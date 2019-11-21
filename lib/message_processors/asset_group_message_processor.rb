require 'message_processor'

module MessageProcessors
  class AssetGroupMessageProcessor < MessageProcessor
    def interested_in?(message)
      !!(message["activity"])
    end

    def process(message)
      _process_activity(params_for_activity(message))
    end

    def _process_asset_group(strong_params)
      asset_group = AssetGroup.find(strong_params[:id])
      assets = strong_params[:assets]
      if asset_group && assets
        begin
          received_list = []

          updates = Asset.changes_for_refresh_or_import_assets_with_barcodes(assets)
          updates.add_assets_to_group(asset_group, assets)
          updates.apply(step_for_add_assets)
          #received_list = assets.map do |uuid_or_barcode|
          #  Asset.find_or_import_asset_with_barcode(uuid_or_barcode)
          #end.compact

          #asset_group.update_with_assets(received_list)

          #asset_group.update_attributes(assets: received_list)
          #asset_group.touch
        rescue Errno::ECONNREFUSED => e
          asset_group.activity.send_wss_event({error: {type: 'danger', msg: 'Cannot connect with sequencescape'} })
        rescue StandardError => e
          asset_group.activity.send_wss_event({error: {type: 'danger', msg: e.message} })
        end
      end
    end

    def step_for_add_assets
      Step.new(activity: asset_group.activity_id, asset_group: asset_group)
    end

    def params_for_asset_group(params)
      params = ActionController::Parameters.new(params)
      params.require(:asset_group).permit(:id, :assets => [])
    end


  end
end
