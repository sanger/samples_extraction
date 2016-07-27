class Action < ActiveRecord::Base
  belongs_to :subject_condition_group, :class_name => 'ConditionGroup'
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  @@TYPES = [:checkFacts, :addFacts, :removeFacts]

  def self.types
    @@TYPES
  end

  def build_fact(created_assets)
    if object_condition_group.nil?
      fact = Fact.new(:predicate => predicate, :object => object)
    else
      fact = Fact.new(
        :predicate => predicate,
        :object => created_assets[object_condition_group.id].barcode
        )
    end
  end

  def execute(step, asset, created_assets, marked_facts_to_destroy)
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

      predicate = facts_to_remove.first.predicate
      object = facts_to_remove.first.object

      operation = Operation.create!(:action => self, :step => step,
        :asset=> asset, :predicate => predicate, :object => object)

      marked_facts_to_destroy.push(facts_to_remove)
      #facts_to_remove.each(&:destroy)
    end
    if asset && fact
      operation = Operation.create!(:action => self, :step => step,
        :asset=> asset, :predicate => fact.predicate, :object => fact.object)
    end

  end
end
