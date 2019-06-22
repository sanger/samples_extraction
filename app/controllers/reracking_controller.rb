class RerackingController < ApplicationController

  before_action :set_activity_type


  before_action :set_activity, :only => [:update, :show]

  def set_activity_type
    @activity_type = ActivityType.available.find_by(name: 'Re-Racking')
  end


  def index
    @activity = Activity.new
  end

end
