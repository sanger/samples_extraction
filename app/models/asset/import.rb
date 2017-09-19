module Asset::Import

  UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  class NotFound < StandardError ; end
  class OutOfDate < StandardError ; end

  module InstanceMethods

    def json_for_remote(remote_asset)
      distinct = remote_asset.attribute_groups.to_json

      # It would be useful to have a hashcode in the sequencescape client api to know
      # if this message is different from a previous one without needing to traverse
      # all the object finding the change
      # Having a :to_json method that returns a json would be pretty sensible too
      if remote_asset.wells
        # wells.to_a because wells relation does not act as an array
        listw = remote_asset.wells.to_a
        if listw
          # aliquots.to_a, same reason
          listal = listw.compact.map(&:aliquots).map(&:to_a)
          if listal
            listsa = listal.flatten.compact.map{|al| al.sample }
            if listsa
              distinct+=listsa.compact.map(&:updated_at).uniq.to_s
            end
          end
        end
      end

      distinct
    end

    def update_digest_with_remote(remote_asset)
      update_attributes(remote_digest: Digest::MD5::hexdigest(json_for_remote(remote_asset)))
    end    

    def changed_remote?(remote_asset)
      Digest::MD5::hexdigest(json_for_remote(remote_asset)) != remote_digest
    end

    def refresh!
      remote_asset = SequencescapeClient::find_by_uuid(uuid)
      @import_step = Step.new(step_type: StepType.find_or_create_by(name: 'Import'))

      raise NotFound unless remote_asset
      if changed_remote?(remote_asset)
        facts_to_remove = [
          facts.from_remote_asset, 
          # We need to destroy also the remote facts of the contained wells on refresh
          facts.with_predicate('contains').map(&:object_asset).map{|w| w.facts.from_remote_asset}
        ].flatten
        remove_operations(facts_to_remove, @import_step)
        facts_to_remove.each(&:destroy)
        self.class.update_asset_from_remote_asset(self, remote_asset)
      end
      self
    end

    def import!
      remote_asset = SequencescapeClient::get_remote_asset(barcode)
      if remote_asset
        update_attributes!(uuid: remote_asset.uuid)
        refresh!
      else
        raise NotFound
      end
      update_compatible_activity_type
      self
    end    

    def is_remote_asset?
      facts.from_remote_asset.count > 0
    end

    def update_facts_from_remote(list)
      list = [list].flatten
      added = list.map do |f| 
        f.assign_attributes(:is_remote? => true) 
        f
      end
      facts << added
      add_operations([added].flatten, @import_step)
    end

  end

  module ClassMethods

    def create_local_asset(barcode)
      asset=nil
      ActiveRecord::Base.transaction do
        asset = Asset.create!(:barcode => barcode)
        asset.update_facts_from_remote([
          Fact.new(:predicate => 'a', :object => 'Tube', is_remote?: true), 
          Fact.new(:predicate => 'barcodeType', :object => 'Code2D', is_remote?: true),
          Fact.new(:predicate => 'is', :object => 'Empty', is_remote?: true)
          ])
      end
      asset   
    end

    def is_local_asset?(barcode)
      Barcode.is_creatable_barcode?(barcode.to_s)      
    end

    def is_digit_barcode?(barcode)
      barcode.to_s.match(/^\d+$/)
    end

    def is_uuid?(str)
      UUID_REGEXP.match(str)
    end

    def find_or_import_asset_with_barcode(barcode)
      barcode = barcode.to_s
      unless is_digit_barcode?(barcode) || is_uuid?(barcode)
        barcode = Barcode.calculate_barcode(barcode[0,2], barcode[2, barcode.length-3].to_i).to_s
      end
      
      asset = Asset.find_by_barcode(barcode)
      asset = Asset.find_by_uuid(barcode) unless asset

      ActiveRecord::Base.transaction do 
        asset = Asset.create_local_asset if asset.nil? && is_local_asset?(barcode)

        if asset
          asset.refresh! if asset.is_remote_asset?
        else
          asset = Asset.create(:barcode => barcode)
          asset.import!
        end
      end
      asset
    end


    def update_asset_from_remote_asset(asset, remote_asset)
      @out_of_date = false

      class_name = sequencescape_type_for_asset(remote_asset)
      asset.update_facts_from_remote(Fact.new(:predicate => 'a', :object => class_name))

      if keep_sync_with_sequencescape?(remote_asset)
        asset.update_facts_from_remote(Fact.new(predicate: 'pushTo', object: 'Sequencescape'))
        if remote_asset.try(:plate_purpose, nil)
          asset.update_facts_from_remote(Fact.new(:predicate => 'purpose',
          :object => remote_asset.plate_purpose.name))
        end
      end
      asset.update_facts_from_remote(Fact.new(:predicate => 'is', :object => 'NotStarted'))

      annotate_container(asset, remote_asset)
      annotate_wells(asset, remote_asset)
      annotate_study_name(asset, remote_asset)

      asset.update_digest_with_remote(remote_asset)
      @out_of_date
    end

    def annotate_container(asset, remote_asset)
      if remote_asset.try(:aliquots, nil)
        remote_asset.aliquots.each do |aliquot|
          asset.update_facts_from_remote(Fact.new(:predicate => 'sample_tube',
            :object_asset => asset))
          asset.update_facts_from_remote(Fact.new(:predicate => 'sanger_sample_id',
            :object => aliquot.sample.sanger.sample_id))
          asset.update_facts_from_remote(Fact.new(:predicate => 'sanger_sample_name',
            :object => aliquot.sample.sanger.name))
          asset.update_facts_from_remote(Fact.new(predicate: 'supplier_sample_name', 
            object: aliquot.sample.supplier.sample_name))        
        end
      end
    end

    def sample_id_to_study_name(sample_id)
      sample_id.gsub(/\d*$/,'').gsub('-', '')
    end

    def annotate_study_name_from_aliquots(asset, remote_asset)
      if remote_asset.try(:aliquots, nil)
        if remote_asset.aliquots.first.sample
          asset.update_facts_from_remote(Fact.new(predicate: 'study_name', 
            object: sample_id_to_study_name(remote_asset.aliquots.first.sample.sanger.sample_id)))
        end
      end    
    end

    def annotate_study_name(asset, remote_asset)
      if remote_asset.try(:wells, nil)
        remote_asset.wells.detect do |w| 
          annotate_study_name_from_aliquots(asset, w)
        end
      else
        annotate_study_name_from_aliquots(asset, remote_asset)
      end
    end

    def annotate_wells(asset, remote_asset)
      if remote_asset.try(:wells, nil)
        remote_asset.wells.each do |well|
          local_well = Asset.find_or_create_by!(:uuid => well.uuid)
          # Only if the supplier name is defined
          if (well.aliquots.first.sample.supplier.sample_name)
            asset.update_facts_from_remote(Fact.new(:predicate => 'contains', :object_asset => local_well))

            # Updated wells will also mean that the plate is out of date, so we'll set it in the asset
            @out_of_date ||= local_well.update_facts_from_remote(Fact.new(:predicate => 'a', :object => 'Well'))
            @out_of_date ||= local_well.update_facts_from_remote(Fact.new(:predicate => 'location', :object => well.location))
            @out_of_date ||= local_well.update_facts_from_remote(Fact.new(:predicate => 'parent', :object_asset => asset))

            annotate_container(local_well, well)
          end
        end
      end
    end

    def sequencescape_type_for_asset(remote_asset)
      remote_asset.class.to_s.gsub(/Sequencescape::/,'')
    end

    def keep_sync_with_sequencescape?(remote_asset)
      class_name = sequencescape_type_for_asset(remote_asset)
      (class_name != 'SampleTube')
    end

  end
end
