require 'message_processor'

module MessageProcessors
  class AssetGroupMessageProcessor < MessageProcessor
    def interested_in?(message)
      !!(message["asset_group"])
    end

    def process(message)
      _process_asset_group(params_for_asset_group(message))
    end

    def _process_asset_group(strong_params)
      asset_group = AssetGroup.find(strong_params[:id])
      assets = strong_params[:assets]
      if asset_group && assets
        debugger
        begin
          FactChanges.new.tap do |updates|
            updates.remove_assets_from_group(asset_group, asset_group.assets)
            Asset.changes_for_refresh_or_import_assets_with_barcodes(assets)
            updates.merge()
            updates.add_assets_to_group(asset_group, assets)
          end.apply(step_for_changing_group)
        rescue Errno::ECONNREFUSED => e
          asset_group.activity.send_wss_event({error: {type: 'danger', msg: 'Cannot connect with sequencescape'} })
        rescue StandardError => e
          asset_group.activity.send_wss_event({error: {type: 'danger', msg: e.message} })
        end
      end
    end

    def step_for_changing_group
      Step.new(activity: asset_group.activity_id, asset_group: asset_group)
    end

    def params_for_asset_group(params)
      params = ActionController::Parameters.new(params)
      params.require(:asset_group).permit(:id, :assets => [])
    end


  end
end
