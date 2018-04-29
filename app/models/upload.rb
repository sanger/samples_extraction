class AssetGroupFile < ApplicationRecord
  belongs_to :asset_group

  def build_asset
    Asset.create
  end
end
