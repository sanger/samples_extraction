class ChangesController < ApplicationController
  def create
    @step = Step.create(state: 'running')
    json = params_changes.to_json
    @updates = FactChanges.new(json)
    if @updates.apply(@step)
      @step.update_attributes(state: 'complete')
    end
    facts_updated = @updates.assets_updated.map(&:facts)
    render json: {
      step: @step,
      assets: @updates.assets_updated,
      facts: facts_updated,
      dataAssetDisplay: facts_updated.map do |facts|
        helpers.data_asset_display(facts)
      end
    }
  end

  private

  def params_changes
    params.require(:changes).permit!
  end
end
