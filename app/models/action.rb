class Action < ActiveRecord::Base
  belongs_to :subject_condition_group, :class_name => 'ConditionGroup'
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  def build_fact(created_assets)
    if object_condition_group.nil?
      fact = Fact.create(:predicate => predicate, :object => object)
    else
      fact = Fact.create(
        :predicate => predicate,
        :object => created_assets[object_condition_group.id].uuid)
    end
  end

  def execute(step, asset, created_assets)
    activity = step.activity

    if subject_condition_group.conditions.empty?
      asset = created_assets[subject_condition_group.id]
    end
    if action_type == 'selectAsset'
      activity.asset_group.assets << asset
    end
    if action_type == 'createAsset'

      asset = Asset.create!
      created_assets[subject_condition_group.id] = asset
      activity.asset_group.assets << asset

      fact = build_fact(created_assets)
      created_assets[subject_condition_group.id].facts << fact
    end
    if action_type == 'addFacts'
      fact = build_fact(created_assets)
      asset.facts << fact
    end
    if action_type == 'removeFacts'
      facts_to_remove = asset.facts.select{|f| f.predicate == predicate && object.nil? ||
        (f.object == object) }
      predicate = facts.first.predicate
      object = facts.first.object
      facts_to_remove.each(&:destroy)
    end
    if asset && fact
      operation = Operation.create!(:action => self, :step => step,
        :asset=> asset, :predicate => fact.predicate || predicate, :object => fact.object || object)
    end

  end
end
