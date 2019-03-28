class Action < ActiveRecord::Base
  belongs_to :subject_condition_group, :class_name => 'ConditionGroup'
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  belongs_to :step_type
  
  @@TYPES = [:checkFacts, :addFacts, :removeFacts]

  def self.types
    @@TYPES
  end

  def each_connected_asset(sources, destinations, &block)
    if step_type.connect_by == 'position'
      sources.zip(destinations).each {|s,d| yield s,d if d}
    else
      sources.each do |s|
        destinations.each do |d|
          yield s,d
        end
      end
    end
  end

  def sources(assets_group)
    asset_group.classified_by_condition_group(subject_condition_group)
  end

  def destinations(asset_group)
    if object_condition_group.nil?
      sources(asset_group).length.times.map { object }
    else
      asset_group.classified_by_condition_group(object_condition_group)
    end
  end

  def run(asset_group)
    FactChanges.new.tap do |updates|
      destinations = destinations(asset_group)
      if action.action_type == 'createAsset'
        num_assets_to_create(asset_group).times.map{ Asset.new }
        asset_group.classify_assets_in_condition_group(assets, subject_condition_group)
        assets.each do |asset|
          each_connected_asset(assets, destinations) do |s, d|
            updates.add(s, action.predicate, d)
          end
        end
      else
        each_connected_asset(sources(asset_group), destinations) do |source, destination|
          if action.action_type=='addFacts'
            updates.add(source, action.predicate, destination)
          elsif action.action_type == 'removeFacts'
            updates.remove(source, action.predicate, destination)
          elsif action.action_type == 'selectAsset'
            asset_group.assets << source
          elsif action.action_type == 'unselectAsset'
            asset_group.assets.delete(source)
          end
        end
      end
    end
  end

  def num_assets_to_create(asset_group)
    return asset_group.assets.count unless (subject_condition_group.cardinality) && (subject_condition_group.cardinality!=0)
    return [[asset_group.assets.count, subject_condition_group.cardinality].min, 1].max
  end

end
