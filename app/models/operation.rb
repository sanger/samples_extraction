class Operation < ApplicationRecord
  belongs_to :step
  belongs_to :asset
  belongs_to :object_asset, class_name: 'Asset'
  belongs_to :action
  belongs_to :activity

  scope :for_presenting, ->() { includes(:asset, :action) }

  def action_type
    return action.action_type if action
    return attributes["action_type"]
  end

  def object_value
    object || object_asset
  end

  def opposites
    {
      add_facts: :remove_facts, remove_facts: :add_facts,
      create_asset: :remove_facts, delete_asset: :add_facts
    }
  end

  def synonims
    {
      add_facts: :add_facts, remove_facts: :remove_facts,
      create_asset: :add_facts, delete_asset: :remove_facts
    }
  end

  def action_type_for_option(option)
    if (option == :remake)
      synonims[action_type.underscore.to_sym]
    elsif (option == :cancel)
      opposites[action_type.underscore.to_sym]
    end
  end

end
