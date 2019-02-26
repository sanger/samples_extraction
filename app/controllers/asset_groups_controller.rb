class AssetGroupsController < ApplicationController
  before_action :set_asset_group, only: [:show, :update, :print, :upload]
  before_action :set_activity, only: [:show, :update]
  before_action :update_barcodes, only: [:update]

  include ActionController::Live

  include ActivitiesHelper

  def show
    @assets = @asset_group.assets
    @assets_grouped = assets_by_fact_group

    respond_to do |format|
      format.html { render @asset_group }
      format.n3 { render :show }
      format.json { head :ok}
    end
  end


  def update
    @assets = @asset_group.assets
    @assets_grouped = assets_by_fact_group

    head :ok
  end

  def upload
    @file = UploadedFile.create(filename: params[:qqfilename], data: params[:qqfile].read)
    asset = @file.build_asset(content_type: params[:qqfile].content_type)
    @asset_group.assets << asset
    @asset_group.touch

    render json: {success: true}
  end

  def print
    @asset_group.print(@current_user.printer_config, @current_user.username)

    redirect_to :back
  end

  private

    def update_barcodes
      perform_assets_update

      if @alerts
        render json: {errors: @alerts}
      end
    end

    def assets_by_fact_group
      obj_type = Struct.new(:predicate,:object,:to_add_by, :to_remove_by, :object_asset_id)
      @assets.group_by do |a|
        a.facts.map(&:as_json).map do |f|
          obj_type.new(f["predicate"], f["object"])
        end
      end
    end


    def set_activity
      # I need the activity to be able to know the step_types compatible to show.
      @activity = Activity.find(params[:activity_id]) if params[:activity_id]
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_asset_group
      @asset_group = AssetGroup.find(params[:id])
    end

  def perform_assets_update
    if params_update_asset_group[:assets]
      updated_assets = [params_update_asset_group[:assets]].flatten
      received_list = updated_assets.map do |uuid_or_barcode|
        Asset.find_or_import_asset_with_barcode(uuid_or_barcode)
      end.compact
      @asset_group.update_attributes(assets: received_list)
      @asset_group.touch
    end
  end

  def show_alert(data)
    @alerts = [] unless @alerts
    @alerts.push(data)
  end

  def params_update_asset_group
    params.require(:asset_group).permit(:assets => [])
  end

end
