class UploadsController < ApplicationController
  before_action :set_activity, only: [:create]

  def set_activity
    @activity = Activity.find_by_id!(params[:activity_id])
  end

  def create
    if params[:file]
      @upload = Upload.create!(:data => params[:file].read,
        :filename => params[:file].original_filename,
        :activity => @activity,
        :content_type => params[:content_type])
    end
    respond_to do |format|
      if @upload.save
        format.html { redirect_to @upload, notice: 'Upload was successfully created.' }
        format.json { render :show, status: :created }
      else
        format.html { render :new }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end
end
