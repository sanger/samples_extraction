class StepTypesController < ApplicationController
  before_action :set_step_type, only: [:show, :edit, :update, :destroy]

  # GET /step_types
  # GET /step_types.json
  def index
    @step_types = StepType.all
  end

  # GET /step_types/1
  # GET /step_types/1.json
  def show
  end

  # GET /step_types/new
  def new
    @step_type = StepType.new
  end

  # GET /step_types/1/edit
  def edit
  end

  # POST /step_types
  # POST /step_types.json
  def create
    @step_type = StepType.new(step_type_params)

    respond_to do |format|
      if @step_type.save
        format.html { redirect_to @step_type, notice: 'Step type was successfully created.' }
        format.json { render :show, status: :created, location: @step_type }
      else
        format.html { render :new }
        format.json { render json: @step_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /step_types/1
  # PATCH/PUT /step_types/1.json
  def update
    respond_to do |format|
      if @step_type.update(step_type_params)
        format.html { redirect_to @step_type, notice: 'Step type was successfully updated.' }
        format.json { render :show, status: :ok, location: @step_type }
      else
        format.html { render :edit }
        format.json { render json: @step_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /step_types/1
  # DELETE /step_types/1.json
  def destroy
    @step_type.destroy
    respond_to do |format|
      format.html { redirect_to step_types_url, notice: 'Step type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_step_type
      @step_type = StepType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def step_type_params
      params.require(:step_type).permit(:name, :n3_definition, :step_template)
    end
end
