class StepsController < ApplicationController
  before_action :set_step, only: [:show, :edit, :update, :destroy]
  before_action :set_activity, only: [:create]

  before_filter :nested_steps, only: [:index]

  def nested_steps
    if step_params[:activity_id]
      @activity = Activity.find(step_params[:activity_id])
      @steps = @activity.steps
    else
      @steps = Step.all
    end
  end


  # GET /steps
  # GET /steps.json
  def index
    #@steps = Step.all
    respond_to do |format|
      format.html { render 'finished', :layout => false } if @activity
    end
  end

  # GET /steps/1
  # GET /steps/1.json
  def show
  end

  # GET /steps/new
  def new
    @step = Step.new
  end

  # GET /steps/1/edit
  def edit
  end



  def params_for_step_in_progress
    return nil if !params[:step]
    return [{:state => 'done', :assets => [@asset_group.assets] }] unless params[:step][:pairings]
    @pairings = create_step_params[:pairings].values.map do |obj|
      Pairing.new(obj, @step_type)
    end

    unless @pairings.all?(&:valid?)
      flash[:danger] = @pairings.map(&:error_messages).join('\n')
      redirect_to :back
    end

    @pairings.map do |pairing|
      {
      :assets => pairing.assets,
      :state => create_step_params[:state]
      }
    end
  end

  def perform_step
    if params[:step_type]
      valid_step_types = @activity.step_types_for(@assets)
      step_type_to_do = @activity.step_types.find_by_id!(params[:step_type])
      if valid_step_types.include?(step_type_to_do)
        apply_parsers(@asset_group.assets)
        @step_performed = @activity.step(step_type_to_do, @user, params_for_step_in_progress)
        @assets.reload
      end
    end
  rescue Activity::StepWithoutInputs
    flash[:danger] = 'We could not create a new step because we do not have inputs for it'
  end


  # POST /activity/:activity_id/step_type/:step_type_id/create
  def create
    valid_step_types = @activity.step_types_for(@assets)
    step_type_to_do = @activity.step_types.find_by_id!(@step_type.id)
    if valid_step_types.include?(step_type_to_do)
      store_uploads
      @step = @activity.step(step_type_to_do, @current_user, params_for_step_in_progress)
      @activity.reasoning!
    end

    respond_to do |format|
      if @step.save
        #format.html { render @activity}
        format.html { redirect_to @activity, notice: 'Step was successfully created.' }
        #format.html { respond_with @activity }
        format.json { render :show, status: :created, location: @step }
        #return
      else
        format.html { render :new }
        format.json { render json: @step.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /steps/1
  # PATCH/PUT /steps/1.json
  def update
    store_uploads
    respond_to do |format|
      if @step.update(step_params)
        format.html { redirect_to @step, notice: 'Step was successfully updated.' }
        format.json { render :show, status: :ok, location: @step }
      else
        format.html { render :edit }
        format.json { render json: @step.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /steps/1
  # DELETE /steps/1.json
  def destroy
    @step.destroy
    respond_to do |format|
      format.html { redirect_to steps_url, notice: 'Step was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_step
      @step = Step.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def step_params
      params.permit(:activity_id, :step_type_id, :id)
      #params.fetch(:step, {})
    end

    def create_step_params
      params.require(:step).permit!
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params[:activity_id])
      @asset_group = @activity.asset_group
      @assets = @asset_group.assets
      @step_type = StepType.find(params[:step_type_id])
    end


    def store_uploads
      if params[:file]
        @upload = Upload.create!(:data => params[:file].read,
          :filename => params[:file].original_filename,
          :activity => @activity,
          :step => @step,
          :content_type => params[:content_type])
      end
    end

end
