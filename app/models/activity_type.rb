class ActivityType < ActiveRecord::Base
  has_many :activities
  has_many :activity_type_step_types
  has_many :step_types, :through => :activity_type_step_types

  #def create_activity
  #  activity = Activity.new(:activity_type => self)
  #  activities << activity
  #  activity
  #end
end
