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

    def applied_errors(step, updates)
      step.update_attributes(state: 'failed')
      step.save
      step.set_errors(updates.to_h[:set_errors])
    end

    def _process_asset_group(strong_params)
      @asset_group = AssetGroup.find(strong_params[:id])
      assets = strong_params[:assets]
      if asset_group && assets
        importer = Importers::BarcodesImporter.new(assets)
        updates = importer.process

        step_for_import = Step.new(
          step_type: StepType.find_or_create_by(name: 'AssetGroupMessageProcessor'),
          user: current_user,
          activity_id: asset_group.activity_owner_id,
          asset_group: asset_group,
          state: 'complete'
        )
        return applied_errors(step_for_import, updates) if updates.has_errors?

        updates.remove_assets_from_group(asset_group, asset_group.assets.to_a)
        updates.add_assets_to_group(asset_group, importer.assets_for_barcodes)

        unless (updates.to_h.keys.length == 0)
          step_for_import.save
          return applied_errors(step_for_import, updates) if updates.has_errors?
          updates.apply(step_for_import)
          step_for_import.wss_event
        end
      end
    end

    def params_for_asset_group(params)
      params = ActionController::Parameters.new(params)
      params.require(:asset_group).permit(:id, :assets => [])
    end


  end
end
