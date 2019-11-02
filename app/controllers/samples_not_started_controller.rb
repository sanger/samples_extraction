class SamplesNotStartedController < SamplesStatusController

  private

  def get_assets_for_activity_type(activity_type)
    activity_type.assets.not_started.paginate(pagination_params_for_activity_type(activity_type))
  end

end
