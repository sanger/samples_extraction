class ProcessTypesController < ApplicationController
  before_action :set_process_type, only: [:show, :edit, :update, :destroy]

  # GET /process_types
  # GET /process_types.json
  def index
    @process_types = ProcessType.all
  end

  # GET /process_types/1
  # GET /process_types/1.json
  def show
  end

  # GET /process_types/new
  def new
    @process_type = ProcessType.new
  end

  # GET /process_types/1/edit
  def edit
  end

  # POST /process_types
  # POST /process_types.json
  def create
    @process_type = ProcessType.new(process_type_params)

    respond_to do |format|
      if @process_type.save
        format.html { redirect_to @process_type, notice: 'Process type was successfully created.' }
        format.json { render :show, status: :created, location: @process_type }
      else
        format.html { render :new }
        format.json { render json: @process_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /process_types/1
  # PATCH/PUT /process_types/1.json
  def update
    respond_to do |format|
      if @process_type.update(process_type_params)
        format.html { redirect_to @process_type, notice: 'Process type was successfully updated.' }
        format.json { render :show, status: :ok, location: @process_type }
      else
        format.html { render :edit }
        format.json { render json: @process_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /process_types/1
  # DELETE /process_types/1.json
  def destroy
    @process_type.destroy
    respond_to do |format|
      format.html { redirect_to process_types_url, notice: 'Process type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_process_type
      @process_type = ProcessType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def process_type_params
      params.require(:process_type).permit(:name)
    end
end
