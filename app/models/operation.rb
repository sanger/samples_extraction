class Operation < ApplicationRecord
  belongs_to :step
  belongs_to :asset
  belongs_to :object_asset, class_name: 'Asset'
  belongs_to :action
  belongs_to :activity

  scope :for_presenting, ->() { includes(:asset, :action) }

  #def action_type
  #  return action.action_type if action
  #  return attributes["action_type"]
  #end

  def object_value
    object || object_asset
  end

  def opposites
    {
      add_facts: :remove_facts, remove_facts: :add_facts,
      create_assets: :delete_assets, delete_assets: :create_assets,
      create_asset_groups: :delete_asset_groups, add_assets: :remove_assets
    }
  end

  def action_type_for_option(option)
    if (option == :remake)
      action_type.underscore.to_sym
    elsif (option == :cancel)
      opposites[action_type.underscore.to_sym]
    end
  end

  def generate_changes_for(option_name, updates=nil)
    updates ||= FactChanges.new
    type = action_type_for_option(option_name)
    if (type == :add_facts)
      updates.add(asset, predicate, object_value)
    elsif (type == :remove_facts)
      updates.remove(Fact.where(asset: asset, predicate: predicate, object: object, object_asset: object_asset))
    elsif (type == :create_assets)
      asset = Asset.create(uuid: object)
      update_attributes(asset: asset)
      updates.create_assets([asset.uuid])
    elsif (type == :delete_assets)
      updates.delete_assets([object])
    elsif (type == :add_assets)
      updates.add_assets([[AssetGroup.find_by(uuid: object), [self.asset]]])
    elsif (type == :remove_assets)
      updates.remove_assets([[AssetGroup.find_by(uuid: object), [self.asset]]])
    elsif (type == :create_asset_groups)
      updates.create_asset_groups([object])
    elsif (type == :delete_asset_groups)
      updates.delete_asset_groups([object])
    end
    updates
  end

end
