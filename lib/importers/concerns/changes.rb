require 'importers/concerns/annotator'

module Importers
  module Concerns
    module Changes

      def refresh_assets(assets, opts={})
        FactChanges.new.tap do |updates|
          if assets.length > 0
            remote_assets = SequencescapeClient::find_by_uuid(assets.map(&:uuid))
            remote_assets = [] if remote_assets.nil?
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
        FactChanges.new.tap do |updates|
          if barcodes.length > 0
            remote_assets = SequencescapeClient::get_remote_asset(barcodes)
            remote_assets = [] if remote_assets.nil?
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
