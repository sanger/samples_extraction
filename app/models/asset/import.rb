module Asset::Import

  UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  class RefreshSourceNotFoundAnymore < StandardError ; end

  module InstanceMethods

    def json_for_remote(remote_asset)
      distinct = remote_asset.attribute_groups.to_json

      # It would be useful to have a hashcode in the sequencescape client api to know
      # if this message is different from a previous one without needing to traverse
      # all the object finding the change
      # Having a :to_json method that returns a json would be pretty sensible too

      # FOR A PLATE
      if remote_asset.respond_to?(:wells) && remote_asset.wells
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

      # FOR A TUBE
      if remote_asset.respond_to?(:aliquots) && remote_asset.aliquots
        # aliquots.to_a, same reason
        listal = remote_asset.aliquots.to_a
        if listal
          listsa = listal.flatten.compact.map{|al| al.sample }
          if listsa
            distinct+=listsa.compact.map(&:updated_at).uniq.to_s
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

    def assets_to_refresh
      # We need to destroy also the remote facts of the contained wells on refresh
      [self, facts.with_predicate('contains').map(&:object_asset).select do |asset|
        asset.facts.from_remote_asset.count > 0
      end].flatten
    end

    def get_import_step
      @import_step
    end

    def _process_refresh(remote_asset, fact_changes=nil)
      fact_changes ||= FactChanges.new
      asset_group = AssetGroup.new
      @import_step.update_attributes(asset_group: asset_group)

      begin
        fact_changes.tap do |updates|
          asset_group.update_attributes(assets: assets_to_refresh)

          # Removes previous state

          assets_to_refresh.each do |asset|
            updates.remove(asset.facts.from_remote_asset)
          end

          # Loads new state
          self.class.update_asset_from_remote_asset(self, remote_asset, updates)
        end.apply(@import_step)
        @import_step.update_attributes(state: 'complete')
        asset_group.touch
      ensure
        @import_step.update_attributes(state: 'error') unless @import_step.state == 'complete'
        @import_step.asset_group.touch if @import_step.asset_group
      end
    end

    def is_refreshing_right_now?
      Step.running_with_asset(self).count > 0
    end

    def type_of_asset_for_sequencescape
      if ((facts.with_predicate('a').first) && (facts.with_predicate('a').first.object.include?("Tube")))
        :tube
      else
        :plate
      end
    end

    def refresh(fact_changes=nil)
      if is_remote_asset?
        remote_asset = SequencescapeClient::find_by_uuid(uuid, type = type_of_asset_for_sequencescape)
        raise RefreshSourceNotFoundAnymore unless remote_asset
        if changed_remote?(remote_asset)
          unless is_refreshing_right_now?
            @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Refresh'), state: 'running')
            _process_refresh(remote_asset, fact_changes)
          end
        end
      end
      self
    end

    def refresh!(fact_changes=nil)
      @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Refresh!!'), state: 'running')
      remote_asset = SequencescapeClient::find_by_uuid(uuid, type = type_of_asset_for_sequencescape)
      raise RefreshSourceNotFoundAnymore unless remote_asset
      _process_refresh(remote_asset, fact_changes)
      self
    end

    def is_remote_asset?
      facts.from_remote_asset.count > 0
    end

    def update_facts_from_remote(list, step=nil)
      step = step || @import_step
      list = [list].flatten
      added = list.map do |f|
        f.assign_attributes(:is_remote? => true)
        f
      end
      facts << added
      add_operations([added].flatten, step)
    end

  end

  module ClassMethods

    def import(barcode)
      asset = nil

      barcode = barcode_from_str(barcode)

      @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Import'), state: 'running')
      remote_asset = SequencescapeClient::get_remote_asset(barcode)

      if remote_asset
        asset = Asset.create(barcode: barcode, uuid: remote_asset.uuid)
        FactChanges.new.tap do |updates|
          updates.add_remote(asset, 'a', sequencescape_type_for_asset(remote_asset))
          updates.add_remote(asset, 'remoteAsset', remote_asset.uuid)
        end.apply(@import_step)
        asset.refresh
        asset.update_compatible_activity_type
      end
      asset
    end

    def create_local_asset(barcode, updates)
      asset=nil
      ActiveRecord::Base.transaction do
        asset = Asset.create!(:barcode => barcode)
        updates.add(asset, 'a', 'Tube')
        updates.add(asset, 'barcodeType', 'Code2D')
        updates.add(asset, 'is', 'Empty')
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

    def barcode_from_str(barcode)
      barcode = barcode.to_s
      unless is_digit_barcode?(barcode) || is_uuid?(barcode)
        parsed = Barcode.creatable_barcode_parsing(barcode)
        barcode = Barcode.calculate_barcode(parsed[:prefix], parsed[:number]).to_s

        #barcode = Barcode.calculate_barcode(barcode[0,2], barcode[2, barcode.length-3].to_i).to_s
      end
      barcode
    end

    def find_asset_with_barcode(barcode_str)
      barcode = barcode_from_str(barcode_str)
      asset = Asset.find_by_barcode(barcode)
      asset = Asset.find_by_uuid(barcode) unless asset
      updates = FactChanges.new
      if asset.nil? && is_local_asset?(barcode_str)
        asset = Asset.create_local_asset(barcode_str, updates)
      end
      if asset
        asset.refresh(updates)
      end
      asset
    end

    def find_or_import_asset_with_barcode(barcode)
      find_asset_with_barcode(barcode) || import(barcode)
    end

    def update_asset_from_remote_asset(asset, remote_asset, fact_changes)
      fact_changes.tap do |updates|
        class_name = sequencescape_type_for_asset(remote_asset)
        updates.add_remote(asset, 'a', class_name)

        if keep_sync_with_sequencescape?(remote_asset)
          updates.add_remote(asset, 'pushTo', 'Sequencescape')
          if remote_asset.try(:plate_purpose, nil)
            updates.add_remote(asset, 'purpose', remote_asset.plate_purpose.name)
          end
        end
        updates.add_remote(asset, 'is', 'NotStarted')

        annotate_container(asset, remote_asset, updates)
        annotate_wells(asset, remote_asset, updates)
        annotate_study_name(asset, remote_asset, updates)

        asset.update_digest_with_remote(remote_asset)
      end
    end

    def annotate_container(asset, remote_asset, fact_changes)
      fact_changes.tap do |updates|
        if remote_asset.try(:aliquots, nil)
          remote_asset.aliquots.each do |aliquot|
            updates.add_remote(asset, 'sample_tube', asset)
            updates.add_remote(asset, 'sanger_sample_id', aliquot&.sample&.sanger&.sample_id)
            updates.add_remote(asset, 'sanger_sample_name', aliquot&.sample&.sanger&.name)
            updates.add_remote(asset, 'supplier_sample_name', aliquot&.sample&.supplier&.sample_name)
          end
        end
      end
    end

    def sample_id_to_study_name(sample_id)
      sample_id.gsub(/\d*$/,'').gsub('-', '')
    end

    def annotate_study_name_from_aliquots(asset, remote_asset, fact_changes)
      fact_changes.tap do |updates|
        if remote_asset.try(:aliquots, nil)
          if ((remote_asset.aliquots.count == 1) && (remote_asset.aliquots.first.sample))
            updates.add_remote(asset, 'study_name', sample_id_to_study_name(remote_asset.aliquots.first.sample.sanger.sample_id))
          end
        end
      end
    end

    def annotate_study_name(asset, remote_asset, fact_changes)
      if remote_asset.try(:wells, nil)
        remote_asset.wells.detect do |w|
          annotate_study_name_from_aliquots(asset, w, fact_changes)
        end
      else
        annotate_study_name_from_aliquots(asset, remote_asset, fact_changes)
      end
    end

    def annotate_wells(asset, remote_asset, fact_changes)
      fact_changes.tap do |updates|
        if remote_asset.try(:wells, nil)
          remote_asset.wells.each do |well|
            local_well = Asset.find_or_create_by!(:uuid => well.uuid)
            if (well.try(:aliquots, nil)&.first&.sample&.supplier&.sample_name)
              updates.add_remote(asset, 'contains', local_well)

              # Updated wells will also mean that the plate is out of date, so we'll set it in the asset
              updates.add_remote(local_well, 'a', 'Well')
              updates.add_remote(local_well, 'location', well.location)
              updates.add_remote(local_well, 'parent', asset)

              annotate_container(local_well, well, fact_changes)
            end
          end
        end
      end
    end

    def sequencescape_type_for_asset(remote_asset)
      type = remote_asset.class.to_s.gsub(/Sequencescape::/,'')
      return 'SampleTube' if type == 'Tube'
      return type
    end

    def keep_sync_with_sequencescape?(remote_asset)
      class_name = sequencescape_type_for_asset(remote_asset)
      (class_name != 'SampleTube')
    end

  end
end
