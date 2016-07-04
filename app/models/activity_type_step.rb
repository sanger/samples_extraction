class ActivityTypeStepType < ActiveRecord::Base
  has_many :step_types
  has_many :activity_types
end
