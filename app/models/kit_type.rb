class KitType < ApplicationRecord
  belongs_to :activity_type
  has_many :kits
end
