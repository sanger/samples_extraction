class StepsController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_step, only: [:update]
  before_action :set_activity, only: [:create]
  before_action :set_asset_group, only: [:create]
  before_action :set_step_type, only: [:create]

  include ActivitiesHelper

  def new
    @step = Step.new
  end

  def create
    @activity.create_step(step_type: @step_type, user: @current_user, asset_group: @asset_group)
    head :ok
  end

  def update
    ActiveRecord::Base.transaction do
      @step.activity.editing! if @step.activity
      @step.send(event_for_step)
      @step.activity.in_progress! if @step.activity
    end

    head :ok
  end

  private

  def event_for_step
    "#{params_step[:event_name]}!"
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_activity
    @activity = Activity.find(params[:activity_id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_step
    @step = Step.find(params[:id])
  end

  def set_asset_group
    @asset_group = AssetGroup.find(params_step[:asset_group_id])
  end

  def set_step_type
    @step_type = StepType.find(params_step[:step_type_id])
  end

  def params_step
    params.require(:step).permit(:step_type_id, :asset_group_id, :tube_printer_id, :plate_printer_id, :event_name)
  end
end
