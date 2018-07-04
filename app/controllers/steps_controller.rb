require 'pry'

class StepsController < ApplicationController
  before_action :set_step, only: [:update]
  before_action :set_activity, only: [:create]
  before_action :set_printer_config, only: [:create]
  before_action :set_asset_group, only: [:create]
  before_action :set_step_type, only: [:create]

  include ActivitiesHelper

  def new
    @step = Step.new
  end

  def create
    #@activity.running!
    @activity.do_task(@step_type, @current_user, params_step, @printer_config, @asset_group)
    #@activity.running!

    head :ok
  end

  def update
    @step.activity.editing! if @step.activity
    @step.update({state: params_step[:state]})
    @step.activity.in_progress! if @step.activity

    head :ok
  end

  private

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

    def set_printer_config
      tube_printer = Printer.find_by(id: params_step[:tube_printer_id]) || nil
      plate_printer = Printer.find_by(id: params_step[:plate_printer_id]) ||  nil
      tube_rack_printer = Printer.find_by(id: params_step[:plate_printer_id]) || nil
      @printer_config = {
        'Tube' => tube_printer.nil? ? "" : tube_printer.name,
        'Plate' => plate_printer.nil? ? "" : plate_printer.name,
        'TubeRack' => tube_rack_printer.nil? ? "" : tube_rack_printer.name
      }
    end

    def params_step
      params.require(:step).permit(:step_type_id, :asset_group_id, :tube_printer_id, :plate_printer_id,
        :state, :triples)
    end

end
