class Kit < ActiveRecord::Base
  belongs_to :kit_type
  has_many :activities

  validates :kit_type, :presence => true
end
