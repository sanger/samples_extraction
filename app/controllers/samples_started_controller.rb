class SamplesStartedController < SamplesStatusController

  private

  def get_assets_for_activity_type(activity_type)
    Asset.started.for_activity_type(activity_type).paginate(pagination_params_for_activity_type(activity_type))
  end

end
