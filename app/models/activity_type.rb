class ActivityType < ActiveRecord::Base
  has_many :activities
  has_many :activity_type_step_types
  has_many :step_types, :through => :activity_type_step_types
  has_and_belongs_to_many :instruments
end
