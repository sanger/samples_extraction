class ActivitiesController < ApplicationController
  before_action :set_activity, only: [:show, :update, :step_types_active, :steps_finished, :steps_finished_with_operations]
  before_action :select_assets, only: [:show, :update, :step_types_active, :steps_finished, :steps_finished_with_operations]

  before_action :set_kit, only: [:create]
  before_action :set_instrument, only: [:create]

  before_action :set_user, only: [:update]

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


  def step_types_active
    @step_types = @activity.step_types_for(@assets)

    respond_to do |format|
      format.html {
        render 'steps/_active', :locals => {
          :step_types => @step_types,
          :activity => @activity
        }, :layout => false
      }
    end
  end

  def steps_finished
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html {
        render 'steps/_finished', :locals => {
          :steps => @steps,
          :activity => @activity,
        }, :layout => false
      }
    end
  end

  def steps_finished_with_operations
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html {
        render 'steps/_finished', :locals => {
          :steps => @steps,
          :activity => @activity,
          :selected_step_id => params[:step_id]
        }, :layout => false
      }
    end
  end

  private

    def set_user
      @user = User.find_by_barcode!(params[:user_barcode])
    rescue ActiveRecord::RecordNotFound => e
      flash[:danger] = 'User not found'
      redirect_to :back    
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

    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params[:id])
      @asset_group = @activity.asset_group
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def activity_params
      params.require(:activity).permit(:kit_barcode, :asset_barcode, :step_type, :instrument_barcode, :delete_barcode)
    end


  def select_assets
    @assets = @activity.asset_group.assets.includes(:facts)
  end

  def set_uploaded_files
    @upload_ids = []
    if params[:upload_ids]
      @upload_ids = JSON.parse(params[:upload_ids])
    end
  end

  def perform_previous_step_type
    if params[:step_type]
      valid_step_types = @activity.step_types_for(@assets)
      step_type_to_do = @activity.step_types.find_by_id!(params[:step_type])
      if valid_step_types.include?(step_type_to_do)
        @step_performed = @activity.create_step(step_type_to_do, @user)
        @upload_ids.each do |upload_id|
          @step_performed.uploads << Upload.find_by_id!(upload_id)
        end
        @upload_ids=[]
        @assets.reload
      end
    end
  end

end
