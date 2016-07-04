class AssetFact < ActiveRecord::Base
  belongs_to :asset
  belongs_to :fact, :class_name => 'Fact'
end
