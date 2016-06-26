class ProcessTypeStepType < ActiveRecord::Base
  belongs_to :process_type
  belongs_to :step_type
end
