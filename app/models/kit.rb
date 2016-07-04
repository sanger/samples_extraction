class Kit < ActiveRecord::Base
  belongs_to :kit_type
  has_many :activities
end
