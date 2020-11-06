class AssetGroupsAsset < ApplicationRecord
  belongs_to :asset
  belongs_to :asset_group
end
