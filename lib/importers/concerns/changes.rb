require 'importers/concerns/annotator'

module Importers
  module Concerns
    module Changes

      def refresh_assets(assets, opts={})
        assets = [assets].flatten
        FactChanges.new.tap do |updates|
          if assets.length > 0
            errors = []
            remote_assets = SequencescapeClient::find_by_uuid(assets.map(&:uuid), errors)
            updates.set_errors(errors) if errors.length > 0

            remote_assets = [] if remote_assets.nil?
            remote_assets = [remote_assets].flatten

            remote_assets.each_with_index do |remote_asset, index|
              asset = assets[index]
              updates.set_errors(["Cannot find the asset #{asset.barcode || asset.uuid} anymore in Sequencescape"]) unless remote_asset
            end

            return updates if updates.has_errors?

            assets.zip(remote_assets).each do |asset, remote_asset|
              annotator = Importers::Concerns::Annotator.new(asset, remote_asset)
              annotator.validate!
              @annotators_by_uuid[asset.uuid]=annotator
              if annotator.has_changes_between_local_and_remote?
                updates.merge(annotator.update_asset_from_remote_asset)
              end
            end
          end
        end
      end

      def import_barcodes(barcodes)
        barcodes = [barcodes].flatten
        FactChanges.new.tap do |updates|
          if barcodes.length > 0
            errors = []
            remote_assets = SequencescapeClient::get_remote_asset(barcodes, errors)
            updates.set_errors(errors) if errors.length > 0

            remote_assets = [] if remote_assets.nil?
            remote_assets = [remote_assets].flatten


            remote_assets.each_with_index do |remote_asset, index|
              updates.set_errors(["Cannot find the barcode #{barcodes[index]} in Sequencescape"]) unless remote_asset
            end

            return updates if updates.has_errors?

            barcodes.zip(remote_assets).each do |barcode, remote_asset|
              if remote_asset
                # Needed in order to identify the imported elements
                @imported_uuids_by_barcode[barcode] = remote_asset.uuid

                asset = Asset.new(barcode: barcode, uuid: remote_asset.uuid)
                annotator = Importers::Concerns::Annotator.new(asset, remote_asset)
                annotator.validate!
                @annotators_by_uuid[asset.uuid]=annotator
                updates.merge(annotator.import_asset_from_remote_asset)
              end
            end
          end
        end
      end

    end
  end
end
