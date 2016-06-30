class ActivitiesController < ApplicationController
  before_action :set_activity, only: [:show, :update]
  before_action :remove_barcodes, only: [:update, :show]
  before_action :add_barcodes, only: [:update, :show]
  before_action :select_assets, only: [:show, :update]

  before_action :set_kit, only: [:create]
  before_action :set_instrument, only: [:create]


  def update
    perform_previous_step_type
    @step_types = @activity.step_types_for(@assets)
    @steps = @activity.steps

    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end

  def show
    @step_types = @activity.step_types_for(@assets)
    @steps = @activity.steps

    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end

  def index
  end

  def set_kit
    @kit = Kit.find_by_barcode!(params[:kit_barcode])
  rescue ActiveRecord::RecordNotFound => e
    flash[:danger] = 'Kit not found'
    redirect_to :back
  end

  def set_instrument
    @instrument = Instrument.find_by_barcode!(params[:instrument_barcode])
  rescue RecordNotFound => e

  end

  def create
    @asset_group = AssetGroup.create
    @activity = @kit.kit_type.activity_type.activities.create(
      :instrument => @instrument,
      :asset_group => @asset_group,
      :kit => @kit)

    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: 'Activity was successfully created.' }
        format.json { render :show, status: :created, location: @activity }
      else
        format.html { render :new }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def activity_params
      params.require(:activity).permit(:kit_barcode, :asset_barcodes)
    end

  def remove_barcodes
    if params[:delete_barcode]
      @activity.unselect_barcodes(params[:delete_barcode].values)
    end
  end

  def add_barcodes
    if params[:asset_barcode]
      @activity.select_barcodes(params[:asset_barcode].values)
    end
  end

  def select_assets
    @assets = @activity.asset_group.assets
  end

  def perform_previous_step_type
    if params[:step_type]
      valid_step_types = @activity.step_types_for(@assets)
      step_type_to_do = @activity.step_types.find_by_id!(params[:step_type])
      if valid_step_types.include?(step_type_to_do)
        @step_performed = @activity.create_step(step_type_to_do)
        @assets.reload
      end
    end
  end

end
