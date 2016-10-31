class Operation < ApplicationRecord
  belongs_to :step
  belongs_to :asset
  belongs_to :action
  belongs_to :activity

  scope :for_presenting, ->() { includes(:asset, :action) }

  def action_type
    return action.action_type if action
    return attributes["action_type"]
  end
end
