module Importers
  module Concerns
    module Annotator
      def update_asset_from_remote_asset(asset, remote_asset)
        FactChanges.new.tap do |updates|
          class_name = sequencescape_type_for_asset(remote_asset)
          updates.replace_remote(asset, 'a', class_name)

          if keep_sync_with_sequencescape?(remote_asset)
            updates.replace_remote(asset, 'pushTo', 'Sequencescape')
            if remote_asset.try(:plate_purpose)
              updates.replace_remote(asset, 'purpose', remote_asset.plate_purpose.name)
            end
          end
          updates.replace_remote(asset, 'is', 'NotStarted')

          updates.merge(annotate_container(asset, remote_asset))
          updates.merge(annotate_wells(asset, remote_asset))
          updates.merge(annotate_study_name(asset, remote_asset))

          updates.merge(update_digest_with_remote(asset, remote_asset))
        end
      end


      def annotate_container(asset, remote_asset)
        FactChanges.new.tap do |updates|
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

      def annotate_study_name_from_aliquots(asset, remote_asset)
        FactChanges.new.tap do |updates|
          if remote_asset.try(:aliquots)
            if ((remote_asset.aliquots.count == 1) && (remote_asset.aliquots.first.sample))
              updates.replace_remote(asset, 'study_name', remote_asset.aliquots.first.study.name)
              updates.replace_remote(asset, 'study_uuid', TokenUtil.quote(remote_asset.aliquots.first.study.uuid), literal: true)
            end
          end
        end
      end

      def annotate_study_name(asset, remote_asset)
        FactChanges.new.tap do |updates|
          if remote_asset.try(:wells)
            remote_asset.wells.each do |w|
              updates.merge(annotate_study_name_from_aliquots(asset, w))
            end
          else
            updates.merge(annotate_study_name_from_aliquots(asset, remote_asset))
          end
        end
      end

      def annotate_wells(asset, remote_asset)
        FactChanges.new.tap do |updates|
          if remote_asset.try(:wells)
            remote_asset.wells.each do |well|
              local_well = Asset.find_by(uuid: well.uuid)
              unless local_well
                local_well = Asset.new(uuid: well.uuid)
                updates.create_assets([local_well])
              end

              updates.replace_remote(asset, 'contains', local_well)

              # Updated wells will also mean that the plate is out of date, so we'll set it in the asset
              updates.replace_remote(local_well, 'a', 'Well')
              updates.replace_remote(local_well, 'location', well.position['name'])
              updates.replace_remote(local_well, 'parent', asset)

              if (well.try(:aliquots)&.first&.sample&.sample_metadata&.supplier_name)
                updates.merge(annotate_container(local_well, well))
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
end
