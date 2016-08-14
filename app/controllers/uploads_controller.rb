class UploadsController < ApplicationController
  before_action :set_activity, only: [:create]

  def set_activity
    @activity = Activity.find_by_id!(params[:activity_id])
  end

end
