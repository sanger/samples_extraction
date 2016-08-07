class AssetGroupsController < ActionController::Base
  before_action :set_asset_group, only: [:show, :update]
  before_action :set_activity, only: [:show, :update]
  before_action :update_barcodes, only: [:update]


  def update
    @assets = @asset_group.assets
    @assets_grouped = assets_by_fact_group
    @step_types = @activity.step_types_active

    respond_to do |format|
      format.html { render @asset_group }
      format.json { render :update, status: :created, location: [@activity, @asset_group] }
    end
  end

  private

    def update_barcodes
      perform_barcode_removal
      perform_barcode_addition
    end

    def assets_by_fact_group
      obj_type = Struct.new(:predicate,:object)
      @assets.group_by do |a|
        a.facts.map(&:as_json).map do |f|
          obj_type.new(f["predicate"], f["object"])
        end
      end
    end


    def set_activity
      # I need the activity to be able to know the step_types compatible to show.
      @activity = Activity.find(params_asset_group[:activity_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_asset_group
      @asset_group = AssetGroup.find(params_asset_group[:id])
    end

  def perform_barcode_removal
    if params_update_asset_group[:delete_barcode]
      @asset_group.unselect_barcodes([params_update_asset_group[:delete_barcode]])
    end
  end

  def perform_barcode_addition
    if params_update_asset_group[:add_barcode]
      barcodes = [params_update_asset_group[:add_barcode]]
      if !@asset_group.select_barcodes(barcodes)
        #flash[:danger] = "Could not find barcodes #{barcodes}"
      end
    end
  end

  def params_update_asset_group
    params.require(:asset_group).permit(:add_barcode, :delete_barcode)
  end

  def params_asset_group
    params.permit(:activity_id, :id, :add_barcode, :delete_barcode)
  end

end
