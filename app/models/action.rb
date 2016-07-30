class Action < ActiveRecord::Base
  belongs_to :subject_condition_group, :class_name => 'ConditionGroup'
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  @@TYPES = [:checkFacts, :addFacts, :removeFacts]

  def self.types
    @@TYPES
  end

  def generate_facts(created_assets, step)
    if object_condition_group.nil?
      facts = [Fact.new(:predicate => predicate, :object => object)]
    else
      if created_assets[object_condition_group.id].nil?
        # If it is not a created object condition group, then it is
        # a condition group from the left side of the rule. It can
        # have N elements, so we'll create the fact for each one.
        # This also means that 'asset' belongs to a condition group
        # with cardinality = 1
        facts = step.asset_group.assets.select do |asset|
          object_condition_group.compatible_with?(asset)
        end.map do |asset|
          Fact.new(
            :predicate => predicate,
            :object => asset.relation_id,
            :literal => false
          )
        end
      else
        facts = [Fact.new(
          :predicate => predicate,
          :object => created_assets[object_condition_group.id].relation_id,
          :literal => false
          )]
      end
    end
    facts
  end

  def execute(step, asset, created_assets, marked_facts_to_destroy)
    if subject_condition_group.conditions.empty?
      asset = created_assets[subject_condition_group.id]
    end
    if action_type == 'selectAsset'
      step.asset_group.assets << asset
    end
    if action_type == 'createAsset'
      asset = Asset.create!
      created_assets[subject_condition_group.id] = asset
      step.asset_group.assets << asset

      facts = generate_facts(created_assets, step)
      created_assets[subject_condition_group.id].facts << facts
    end
    if action_type == 'addFacts'
      facts = generate_facts(created_assets, step)
      asset.facts << facts
    end
    if action_type == 'removeFacts'
      facts_to_remove = asset.facts.select do |f|
        (f.predicate == predicate) && (object.nil? || (f.object == object))
      end

      predicate = facts_to_remove.first.predicate
      object = facts_to_remove.first.object

      operation = Operation.create!(:action => self, :step => step,
        :asset=> asset, :predicate => predicate, :object => object)

      marked_facts_to_destroy.push(facts_to_remove)
      #facts_to_remove.each(&:destroy)
    end
    if asset && facts
      facts.each do |fact|
        operation = Operation.create!(:action => self, :step => step,
          :asset=> asset, :predicate => fact.predicate, :object => fact.object)
      end
    end

  end
end
