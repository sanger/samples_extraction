class ActivitiesController < ApplicationController
  before_action :set_activity, only: [:show, :update]

  def update
    @assets = params[:asset_barcode].map{|b| Asset.find_by_barcode!(b)} unless params[:asset_barcode].nil?
    @step_type = @activity.step_types_for(@assets).first

    if @step_type
      @steps = @activity.steps_for(@assets)
      if params[:asset_group].nil?
        @asset_group = AssetGroup.create(:assets => @assets)
      else
        @asset_group = AssetGroup.find(params[:asset_group])
      end
      @activity.create_step(@step_type, @asset_group)
    else
      @steps = @activity.steps
    end

    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end

  def show
    @steps = @activity.steps

    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end

  def index
  end

  def create
    @kit = Kit.find_by_barcode!(params[:kit_barcode])
    @instrument = Instrument.find_by_barcode!(params[:instrument_barcode])
    @activity = @kit.kit_type.activity_type.activities.create(:instrument => @instrument, :kit => @kit)

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
end
