class UploadedFilesController < ApplicationController
  before_action :set_uploaded_file, only: [:show]

  def show
    respond_to do |format|
      format.bin do
        send_data(@uploaded_file.data, filename: @uploaded_file.filename)
      end
      format.html { render :show }
      format.n3 { render :show }
    end
  end

  private

  def set_uploaded_file
    @uploaded_file = UploadedFile.find(params[:id])
  end
end
