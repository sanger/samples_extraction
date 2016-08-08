class Action < ActiveRecord::Base
  belongs_to :subject_condition_group, :class_name => 'ConditionGroup'
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  @@TYPES = [:checkFacts, :addFacts, :removeFacts]

  def self.types
    @@TYPES
  end

  def generate_facts(created_assets, asset_group, step)
    data = {}
    if object_condition_group.nil?
      data = [{:predicate => predicate, :object => object}]
    else
      if created_assets[object_condition_group.id].nil?
        # If it is not a created object condition group, then it is
        # a condition group from the left side of the rule. It can
        # have N elements, so we'll create the fact for each one.
        # This also means that 'asset' belongs to a condition group
        # with cardinality = 1
        data = asset_group.assets.select do |asset|
          object_condition_group.compatible_with?(asset)
        end.map do |asset|
          {
            :predicate => predicate,
            :object => asset.relation_id,
            :object_asset_id => asset.id,
            :literal => false
          }
        end
      else
        data = created_assets[object_condition_group.id].map do |asset|
          {
          :predicate => predicate,
          :object => asset.relation_id,
          :object_asset_id => asset.id,
          :literal => false
          }
        end
      end
    end
    in_progress = step.in_progress? ? {:to_add_by => step.id} : {}
    data.map do |obj|
      Fact.create(obj.merge(in_progress))
    end
  end

  def execute(step, asset_group, asset, created_assets, marked_facts_to_destroy=nil)
    assets = [asset]
    if subject_condition_group.conditions.empty?
      assets = created_assets[subject_condition_group.id]
    end
    if action_type == 'selectAsset'
      asset_group.assets << asset
    end
    if action_type == 'createAsset'
      unless created_assets[subject_condition_group.id]
        num_create = asset_group.assets.count
        if (subject_condition_group.cardinality) && (subject_condition_group.cardinality!=0)
          num_create = [asset_group.assets.count, subject_condition_group.cardinality].min
        end
        assets = num_create.times.map{|i| Asset.create!}

        # Each fact of a createAsset action is considered an action by
        # itself, because of that, before creating the assets we check
        # if they were already created by a previous action
        created_assets[subject_condition_group.id] = assets
        asset_group.assets << assets
      end
      assets = created_assets[subject_condition_group.id]

      facts = generate_facts(created_assets, asset_group, step)
      created_assets[subject_condition_group.id].each do |created_asset|
        created_asset.facts << facts.map(&:dup)
      end
    end
    if action_type == 'addFacts'
      msg = 'You cannot add facts to an asset not present in the conditions'
      raise Step::UnknownConditionGroup, msg if assets.compact.length==0
      facts = generate_facts(created_assets, asset_group, step)
      assets.each do |asset|
        asset.facts << facts
      end
    end
    if action_type == 'removeFacts'
      assets.each do |asset|
        facts_to_remove = asset.facts.select do |f|
          (f.predicate == predicate) && (object.nil? || (f.object == object))
        end

        facts_to_remove.each do |fact|
          predicate = fact.predicate
          object = fact.object

          operation = Operation.create!(:action => self, :step => step,
            :asset=> asset, :predicate => predicate, :object => object)
        end
        if marked_facts_to_destroy.nil?
          facts_to_remove.each do |fact|
            fact.update_attributes(:to_remove_by => step.id)
          end
        else
          marked_facts_to_destroy.push(facts_to_remove)
        end
      end
    end
    if assets && facts
      assets.each do |asset|
        facts.each do |fact|
          operation = Operation.create!(:action => self, :step => step,
            :asset=> asset, :predicate => fact.predicate, :object => fact.object)
        end
      end
    end

  end
end
