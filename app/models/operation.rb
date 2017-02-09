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

  def object_asset
    if action.object_condition_group
      Asset.find_by(:uuid => object)
    else
      nil
    end
  end

  def object_asset_id
    return nil unless object_asset
    object_asset.id
  end
end
