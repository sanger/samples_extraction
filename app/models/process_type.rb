class ProcessType < ActiveRecord::Base
  has_many :process_type_step_types
  has_many :step_types, :through => :process_type_step_types
end
