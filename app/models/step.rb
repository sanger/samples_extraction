class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  has_one :asset_group

  before_create :execute_actions

  def execute_actions
    #step_type.actions
  end
end
