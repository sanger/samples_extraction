require 'message_processor'
require 'importers/barcodes_importer'
module MessageProcessors
  class AssetGroupMessageProcessor < MessageProcessor
    attr_reader :asset_group

    def interested_in?(message)
      !!(message["asset_group"])
    end

    def process(message)
      _process_asset_group(params_for_asset_group(message))
    end

    def _process_asset_group(strong_params)
      @asset_group = AssetGroup.find(strong_params[:id])
      assets = strong_params[:assets]
      if asset_group && assets
        step_for_import = Step.new(
          step_type: StepType.find_or_create_by(name: 'AssetGroupMessageProcessor'),
          activity_id: asset_group.activity_owner_id,
          asset_group: asset_group,
          state: 'complete'
        )
        importer = Importers::BarcodesImporter.new(assets)
        updates = importer.process
        updates.remove_assets_from_group(asset_group, asset_group.assets.to_a)
        updates.add_assets_to_group(asset_group, importer.assets_for_barcodes)
        updates.apply(step_for_import)
        step_for_import.wss_event
      end
    end

    def params_for_asset_group(params)
      params = ActionController::Parameters.new(params)
      params.require(:asset_group).permit(:id, :assets => [])
    end


  end
end
