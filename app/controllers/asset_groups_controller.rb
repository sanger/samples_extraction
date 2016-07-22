class AssetGroupsController < ActionController::Base
  before_action :set_asset_group, only: [:show, :update]

  def update
    perform_barcode_removal
    perform_barcode_addition

    respond_to do |format|
      #format.html { render :update }
      format.json { render :update, status: :created, location: [@activity, @asset_group] }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_asset_group
      @activity = Activity.find(params[:activity_id])
      @asset_group = AssetGroup.find(params[:id])
    end

  def perform_barcode_removal
    if params[:delete_barcode]
      @asset_group.unselect_barcodes([params[:delete_barcode]])
    end
  end

  def perform_barcode_addition
    if params[:add_barcode]
      barcodes = [params[:add_barcode]]
      if !@asset_group.select_barcodes(barcodes)
        #flash[:danger] = "Could not find barcodes #{barcodes}"
      end
    end
  end

end
