class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  has_one :asset

end
