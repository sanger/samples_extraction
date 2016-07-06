class ActivitiesController < ApplicationController
  before_action :set_activity, only: [:show, :update]
  before_action :remove_barcodes, only: [:update, :show]
  before_action :add_barcodes, only: [:update, :show]
  before_action :select_assets, only: [:show, :update]

  before_action :set_kit, only: [:create]
  before_action :set_instrument, only: [:create]

  before_action :set_uploaded_files, only: [:update]
  before_action :perform_previous_step_type, only: [:update]


  def update
    @activity.finish unless params[:finish].nil?
    @step_types = @activity.step_types_for(@assets)
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end


  def show
    @step_types = @activity.step_types_for(@assets)
    @steps = @activity.previous_steps

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
    @activity_type = @kit.kit_type.activity_type
    @activity = @activity_type.activities.create(
      :instrument => @instrument,
      :activity_type => @activity_type,
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
      params.require(:activity).permit(:kit_barcode, :asset_barcode, :step_type, :instrument_barcode, :delete_barcode)
    end

  def remove_barcodes
    if params[:delete_barcode]
      @activity.unselect_barcodes(params[:delete_barcode].values)
    end
  end

  def add_barcodes
    if params[:asset_barcode]
      barcodes = params[:asset_barcode].values
      if !@activity.select_barcodes(barcodes)
        flash[:danger] = "Could not find barcodes #{barcodes}"
      end
    end
  end

  def select_assets
    @assets = @activity.asset_group.assets
  end

  def set_uploaded_files
    @upload_ids = []
    if params[:upload_ids]
      @upload_ids = params[:upload_ids]
    end

    if params[:file]
      f = Upload.create!(:data => params[:file].read,
        :filename => params[:file].original_filename,
        :content_type => params[:content_type])
      @upload_ids << f.id
    else
    end
  end

  def perform_previous_step_type
    if params[:step_type]
      valid_step_types = @activity.step_types_for(@assets)
      step_type_to_do = @activity.step_types.find_by_id!(params[:step_type])
      if valid_step_types.include?(step_type_to_do)
        @step_performed = @activity.create_step(step_type_to_do)
        @upload_ids.each do |upload_id|
          @step_performed.uploads << Upload.find_by_id!(upload_id)
        end
        @upload_ids=[]
        @assets.reload
      end
    end
  end

end
