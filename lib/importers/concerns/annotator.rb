require 'importers/concerns/remote_digest'

module Importers
  module Concerns
    class Annotator
      include Importers::Concerns::RemoteDigest

      attr_reader :asset, :remote_asset

      def initialize(asset, remote_asset)
        @asset=asset
        @remote_asset = remote_asset
      end

      def validate!
        raise Assets::Import::RefreshSourceNotFoundAnymore unless remote_asset
        raise 'Uuid from asset and remote asset are different' unless asset.uuid == remote_asset.uuid
      end

      def import_asset_from_remote_asset
        FactChanges.new.tap do |updates|
          updates.create_assets([asset])
          updates.replace_remote(asset, 'a', sequencescape_type_for_asset)
          updates.replace_remote(asset, 'remoteAsset', asset)
          updates.merge(update_asset_from_remote_asset)
        end
      end

      def update_asset_from_remote_asset
        FactChanges.new.tap do |updates|
          class_name = sequencescape_type_for_asset
          updates.remove(asset.facts.from_remote_asset)
          updates.replace_remote_property(asset, 'a', class_name)

          if is_not_a_sample_tube?
            updates.replace_remote_property(asset, 'pushTo', 'Sequencescape')
            if remote_asset.try(:plate_purpose)
              updates.replace_remote_property(asset, 'purpose', remote_asset.plate_purpose.name)
            end
          end
          updates.replace_remote_property(asset, 'is', 'NotStarted')

          updates.merge(annotate_container(asset, remote_asset))
          updates.merge(annotate_wells(asset, remote_asset))
          updates.merge(annotate_study_name(asset, remote_asset))

          updates.merge(update_digest_with_remote)
        end
      end

      def update_digest_with_remote
        FactChanges.new.tap do |updates|
          updates.add(asset, 'remote_digest', digest_for_remote_asset)
        end
      end

      def annotate_container(asset, remote_asset)
        FactChanges.new.tap do |updates|
          if remote_asset.try(:aliquots)
            remote_asset.aliquots.each do |aliquot|
              updates.replace_remote_relation(asset, 'sample_tube', asset)
              updates.replace_remote_property(asset, 'sanger_sample_id', aliquot&.sample&.sanger_sample_id)
              updates.replace_remote_property(asset, 'sample_uuid', aliquot&.sample&.uuid)
              updates.replace_remote_property(asset, 'sanger_sample_name', aliquot&.sample&.name)
              updates.replace_remote_property(asset, 'supplier_sample_name', aliquot&.sample&.sample_metadata&.supplier_name)
              updates.replace_remote_property(asset, 'sample_common_name', aliquot&.sample&.sample_metadata&.sample_common_name)
            end
          end
        end
      end

      def annotate_study_name_from_aliquots(asset, remote_asset)
        FactChanges.new.tap do |updates|
          if remote_asset.try(:aliquots)
            if ((remote_asset.aliquots.count == 1) && (remote_asset.aliquots.first.sample))
              updates.replace_remote_property(asset, 'study_name', remote_asset.aliquots.first.study.name)
              updates.replace_remote_property(asset, 'study_uuid', remote_asset.aliquots.first.study.uuid)
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
          # Remove any old wells
          updates.remove(asset.facts.with_predicate('contains').from_remote_asset)
          if remote_asset.try(:wells)
            remote_asset.wells.each do |well|
              local_well = Asset.find_by(uuid: well.uuid)
              unless local_well
                local_well = Asset.new(uuid: well.uuid)
                updates.create_assets([local_well])
              end
              # Remove any old fact information from the well
              updates.remove(local_well.facts.from_remote_asset)

              # Add the new info
              updates.add_remote(asset, 'contains', local_well)

              # Updated wells will also mean that the plate is out of date, so we'll set it in the asset
              updates.replace_remote_property(local_well, 'a', 'Well')
              updates.replace_remote_property(local_well, 'location', well.position['name'])
              updates.replace_remote_relation(local_well, 'parent', asset)

              if (well.try(:aliquots)&.first&.sample&.sample_metadata&.supplier_name)
                updates.merge(annotate_container(local_well, well))
              end
            end
          end
        end
      end

      def sequencescape_type_for_asset
        return nil unless remote_asset.type
        type = remote_asset.type.singularize.classify
        return 'SampleTube' if type == 'Tube'
        return type
      end

      def is_not_a_sample_tube?
        class_name = sequencescape_type_for_asset
        (class_name != 'SampleTube')
      end
    end
  end
end
