module Assets::Import::Facts

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  module InstanceMethods
    def facts_for_refresh
      facts_for_refresh_asset(self)
    end
  end

  module ClassMethods
    def find_or_import_assets_with_barcodes(barcodes)
      updates = facts_for_new_fluidx_tubes(barcodes)
      updates.merge(facts_for_refresh_barcodes(barcodes))
      updates.merge(facts_for_import_new_barcodes(barcodes))
      updates.apply(Step.create(step_type: StepType.find_or_create_by(name: 'Refresh'), state: 'running'))

      _find_assets_with_barcodes(barcodes)
    end

    def facts_for_create_new_tubes(barcodes)
      FactChanges.new.tap do |updates|
        barcodes.each do |barcode|
          asset = Asset.new(barcode: barcode)
          updates.add(asset, 'a', 'Tube')
          updates.add(asset, 'barcodeType', 'Code2D')
          updates.add(asset, 'is', 'Empty')
        end
      end
    end

    def facts_for_refresh_asset(asset)
      FactChanges.new.tap do |updates|
        if asset.is_remote_asset?
          debugger
          remote_asset = SequencescapeClient::find_by_uuid(asset.uuid)
          raise RefreshSourceNotFoundAnymore unless remote_asset
          if changed_remote?(remote_asset)
            unless is_refreshing_right_now?
              assets_to_refresh.each do |asset|
                updates.remove(asset.facts.from_remote_asset)
              end

              # Loads new state
              self.class.update_asset_from_remote_asset(self, remote_asset, updates)
            end
          end
        end
      end
    end

    def facts_for_new_fluidx_tubes(barcodes)
      fluidx_barcodes = barcodes.select{|barcode| TokenUtil.is_valid_fluidx_barcode?(barcode)}
      fluidx_tubes = Asset.where(barcode: fluidx_barcodes)
      fluidx_barcodes_to_create = (fluidx_barcodes - fluidx_tubes.pluck(:barcode))

      facts_for_create_new_tubes(fluidx_barcodes_to_create)
    end

    def facts_for_refresh_barcodes(barcodes)
      FactChanges.new.tap do |updates|
        assets = _find_assets_with_barcodes(barcodes)
        assets.each do |asset|
          updates.merge(facts_for_refresh_asset(asset))
        end
      end
    end


    def facts_for_import_barcode(barcode)
      FactChanges.new.tap do |updates|
        debugger
        remote_asset = SequencescapeClient::get_remote_asset(barcode)

        if remote_asset
          asset = Asset.new(barcode: barcode, uuid: remote_asset.uuid)
          updates.replace_remote(asset, 'a', sequencescape_type_for_asset(remote_asset))
          updates.replace_remote(asset, 'remoteAsset', remote_asset.uuid)
          self.class.update_asset_from_remote_asset(asset, remote_asset, updates)
        end
      end
    end

    def facts_for_import_new_barcodes(barcodes)
      FactChanges.new.tap do |updates|
        assets = _find_assets_with_barcodes(barcodes)
        not_found_barcodes = (barcodes - (assets.map(&:barcode).concat(assets.map(&:uuid)).flatten))
        not_found_barcodes.each do |not_found_barcode|
          updates.merge(facts_for_import_barcode(not_found_barcode))
        end
      end
    end

    def _find_assets_with_barcodes(barcodes)
      Asset.where(barcode: barcodes).or(Asset.where(uuid: barcodes))
    end

  end

end
