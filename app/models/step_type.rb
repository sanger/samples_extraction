class StepType < ActiveRecord::Base
  has_many :process_type_step_types
  has_many :process_types, :through => :process_type_step_types
  has_many :conditions
end
