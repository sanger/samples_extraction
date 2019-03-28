class Action < ActiveRecord::Base
  belongs_to :subject_condition_group, :class_name => 'ConditionGroup'
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  @@TYPES = [:checkFacts, :addFacts, :removeFacts]

  def self.types
    @@TYPES
  end

  def classified_assets(assets)
    [subject_condition_group, object_condition_group].reduce({}) do |memo, cg|
      memo[cg.id] = cg.select_compatible_assets(assets) if cg
      memo
    end
  end

  def sources(assets, position=nil)
    subject_condition_group.select_compatible_assets(assets, position)
  end

  def destinations(assets, position=nil)
    if object_condition_group.nil?
      [object]
    else
      object_condition_group.select_compatible_assets(assets, position)
    end
  end

  def run(changes_manager, position=nil)
    send(action.action_type.underscore, asset_group, position)
  end

  def add_facts(asset_group, position=nil)
    sources = sources(asset_group.assets, position)
    destinations = destinations(asset_group.assets, position)

    changes_manager.fact_changes.tap do |updates|
      sources.map do |source|
        destinations.map do |destination|
          updates.add(source, action.predicate, destination)
        end
      end
    end
  end

  def remove_facts(asset_group, position=nil)
    sources = sources(asset_group.assets, position)
    destinations = destinations(asset_group.assets, position)

    changes_manager.fact_changes.tap do |updates|
      sources.map do |source|
        destinations.map do |destination|
          updates.remove(source, action.predicate, destination)
        end
      end
    end
  end

  def select_asset(asset_group, position=nil)
    sources = sources(asset_group.assets, position)

    changes_manager.asset_group_changes.tap do |updates|
      updates.add(sources)
    end
  end

  def unselect_asset(asset_group, position=nil)
    sources = sources(asset_group.assets, position)

    changes_manager.asset_group_changes.tap do |updates|
      updates.remove(sources)
    end
  end

  def create_asset(asset_group, position=nil)
    sources = num_assets_to_create(asset_group).times.map{ Asset.new }
    classify_as_source(sources)
    add_facts(asset_group, position)
    changes_manager.asset_group_changes.tap do |updates|
      destinations.each do |destination|
        updates.add(num_assets_to_create(asset_group), action.predicate, destination)
      end
    end
  end

  def remove_asset(asset_group, position=nil)
    sources = sources(asset_group.assets, position)
    AssetChanges.new.tap do |updates|
      updates.remove(sources)
    end
  end

  def num_assets_to_create(asset_group)
    return asset_group.assets.count unless (subject_condition_group.cardinality) && (subject_condition_group.cardinality!=0)
    return [[asset_group.assets.count, subject_condition_group.cardinality].min, 1].max
  end

end
