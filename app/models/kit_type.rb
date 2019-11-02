class KitType < ActiveRecord::Base
  belongs_to :activity_type
  has_many :kits
end
