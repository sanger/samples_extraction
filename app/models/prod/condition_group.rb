class Prod::ConditionGroup < ActiveRecord::Base
  belongs_to :step_type
  has_many :conditions
end
