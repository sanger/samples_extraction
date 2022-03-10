class Kit < ApplicationRecord
  belongs_to :kit_type
  has_many :activities
  has_one :activity_type, :through => :kit_type

  def type
    kit_type&.name
  end
end
