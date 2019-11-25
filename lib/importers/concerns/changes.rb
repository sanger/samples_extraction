module Importers
  module Concerns
    module Changes

      def refresh_assets(assets, opts={})
        FactChanges.new.tap do |updates|
          if assets.length > 0
            remote_assets = SequencescapeClient::find_by_uuid(assets.map(&:uuid))
            assets.zip(remote_assets).each do |asset, remote_asset|
              raise Assets::Import::RefreshSourceNotFoundAnymore unless remote_asset
              if ((opts[:forceRefresh]==true) || changed_remote?(asset, remote_asset))
                unless asset.is_refreshing_right_now?
                  asset.assets_to_refresh.each do |asset|
                    updates.remove(asset.facts.from_remote_asset)
                  end

                  # Loads new state
                  updates.merge(update_asset_from_remote_asset(asset, remote_asset))
                end
              end
            end
          end
        end
      end

      def import_barcodes(barcodes)
        FactChanges.new.tap do |updates|
          if barcodes.length > 0
            remote_assets = SequencescapeClient::get_remote_asset(barcodes)
            barcodes.zip(remote_assets).each do |barcode, remote_asset|
              if remote_asset
                # Needed in order to identify the imported elements
                @imported_uuids_by_barcode[barcode] = remote_asset.uuid

                asset = Asset.new(barcode: barcode, uuid: remote_asset.uuid)
                updates.create_assets([asset])
                updates.replace_remote(asset, 'a', sequencescape_type_for_asset(remote_asset))
                updates.replace_remote(asset, 'remoteAsset', asset)
                updates.merge(update_asset_from_remote_asset(asset, remote_asset))
              end
            end
          end
        end
      end

    end
  end
end
