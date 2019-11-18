module Assets::Import

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  class RefreshSourceNotFoundAnymore < StandardError ; end

  module InstanceMethods

    def json_for_remote(remote_asset)
      distinct = remote_asset.attributes.to_json

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
              distinct+=listsa.compact.map(&:attributes).to_json
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
            distinct+=listsa.compact.map(&:attributes).to_json
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

    def is_refreshing_right_now?
      Step.running_with_asset(self).count > 0
    end

    def is_remote_asset?
      facts.from_remote_asset.count > 0
    end

  end

  module ClassMethods

    def find_or_import_asset_with_barcode(barcode)
      find_or_import_assets_with_barcodes([barcode]).first
    end

    def update_asset_from_remote_asset(asset, remote_asset, fact_changes)
      fact_changes.tap do |updates|
        class_name = sequencescape_type_for_asset(remote_asset)
        updates.replace_remote(asset, 'a', class_name)

        if keep_sync_with_sequencescape?(remote_asset)
          updates.replace_remote(asset, 'pushTo', 'Sequencescape')
          if remote_asset.try(:plate_purpose)
            updates.replace_remote(asset, 'purpose', remote_asset.plate_purpose.name)
          end
        end
        updates.replace_remote(asset, 'is', 'NotStarted')

        annotate_container(asset, remote_asset, updates)
        annotate_wells(asset, remote_asset, updates)
        annotate_study_name(asset, remote_asset, updates)

        asset.update_digest_with_remote(remote_asset)
      end
    end


    def annotate_container(asset, remote_asset, fact_changes)
      fact_changes.tap do |updates|
        if remote_asset.try(:aliquots)
          remote_asset.aliquots.each do |aliquot|
            updates.replace_remote(asset, 'sample_tube', asset)
            updates.replace_remote(asset, 'sanger_sample_id', aliquot&.sample&.sanger_sample_id)
            updates.replace_remote(asset, 'sample_uuid', TokenUtil.quote(aliquot&.sample&.uuid), literal: true)
            updates.replace_remote(asset, 'sanger_sample_name', aliquot&.sample&.name)
            updates.replace_remote(asset, 'supplier_sample_name', aliquot&.sample&.sample_metadata&.supplier_name)
            updates.replace_remote(asset, 'sample_common_name', aliquot&.sample&.sample_metadata&.sample_common_name)
          end
        end
      end
    end

    def annotate_study_name_from_aliquots(asset, remote_asset, fact_changes)
      fact_changes.tap do |updates|
        if remote_asset.try(:aliquots)
          if ((remote_asset.aliquots.count == 1) && (remote_asset.aliquots.first.sample))
            updates.replace_remote(asset, 'study_name', remote_asset.aliquots.first.study.name)
            updates.replace_remote(asset, 'study_uuid', TokenUtil.quote(remote_asset.aliquots.first.study.uuid), literal: true)
          end
        end
      end
    end

    def annotate_study_name(asset, remote_asset, fact_changes)
      if remote_asset.try(:wells)
        remote_asset.wells.detect do |w|
          annotate_study_name_from_aliquots(asset, w, fact_changes)
        end
      else
        annotate_study_name_from_aliquots(asset, remote_asset, fact_changes)
      end
    end

    def annotate_wells(asset, remote_asset, fact_changes)
      fact_changes.tap do |updates|
        if remote_asset.try(:wells)
          remote_asset.wells.each do |well|
            local_well = Asset.find_or_create_by!(:uuid => well.uuid)

            updates.replace_remote(asset, 'contains', local_well)

            # Updated wells will also mean that the plate is out of date, so we'll set it in the asset
            updates.replace_remote(local_well, 'a', 'Well')
            updates.replace_remote(local_well, 'location', well.position['name'])
            updates.replace_remote(local_well, 'parent', asset)

            if (well.try(:aliquots)&.first&.sample&.sample_metadata&.supplier_name)
              annotate_container(local_well, well, fact_changes)
            end
          end
        end
      end
    end

    def sequencescape_type_for_asset(remote_asset)
      return nil unless remote_asset.type
      type = remote_asset.type.singularize.classify
      return 'SampleTube' if type == 'Tube'
      return type
    end

    def keep_sync_with_sequencescape?(remote_asset)
      class_name = sequencescape_type_for_asset(remote_asset)
      (class_name != 'SampleTube')
    end

  end
end
