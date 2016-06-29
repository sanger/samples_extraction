class AssetGroup < ActiveRecord::Base
  has_and_belongs_to_many :assets
  has_many :steps
end
