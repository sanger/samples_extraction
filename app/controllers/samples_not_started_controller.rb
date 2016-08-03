class SamplesNotStartedController < ApplicationController
  def index
    @activity_types = ActivityType.all.visible.includes(:step_types).includes(:condition_groups).includes(:conditions)
  end
end
