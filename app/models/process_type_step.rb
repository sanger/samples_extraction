class ProcessTypeStepType < ActiveRecord::Base
  has_many :step_types
  has_many :process_types
end
