class SamplesNotStartedController < ApplicationController
  def index
    @activity_types = ActivityType.all.visible
  end
end
