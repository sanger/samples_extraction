class AssetGroupChannel < ApplicationCable::Channel

  def subscribed
    stream_from "asset_group_#{params[:asset_group_id]}"
  end
end
