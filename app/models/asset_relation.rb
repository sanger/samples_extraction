class AssetRelation < ApplicationRecord
  belongs_to :subject, :class_name => 'Asset'
  belongs_to :object, :class_name => 'Asset'
end
