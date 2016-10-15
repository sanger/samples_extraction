class Action < ActiveRecord::Base
  belongs_to :subject_condition_group, :class_name => 'ConditionGroup'
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  @@TYPES = [:checkFacts, :addFacts, :removeFacts]

  def self.types
    @@TYPES
  end

  def wildcard_facts(asset, step)
    if object_condition_group.is_wildcard?
      values = step.wildcard_values[object_condition_group.id][asset.id]
      values.map do |value|
          {
              :predicate => predicate,
              :object => value,
              :object_asset_id => nil,
              :literal => true
          }
      end
    end
  end


  def generate_facts(created_assets, asset_group, step, asset)
    data = {}
    if object_condition_group.nil?
      data = [{:predicate => predicate, :object => object}]
    else
      if created_assets[object_condition_group.id].nil?
        if object_condition_group.is_wildcard?
          # A wildcard value might be an asset as well, not just values
          # we need to add support to them
          data = wildcard_facts(asset, step)
        else
          data = asset_group.assets.select do |related_asset|
            # They are compatible if the object condition group is
            # compatible and if they share a common range of values of
            # values for any of the wildcard values defined
            object_condition_group.compatible_with?(related_asset) &&
            step.wildcard_values.all? do |cg_id, data|
              (!(data[asset.id] & data[related_asset.id]).empty?)
            end
          end.map do |related_asset|
            {
              :predicate => predicate,
              :object => related_asset.relation_id,
              :object_asset_id => related_asset.id,
              :literal => false

            }
          end
        end
      else
        data = created_assets[object_condition_group.id].map do |related_asset|
          {
          :predicate => predicate,
          :object => related_asset.relation_id,
          :object_asset_id => related_asset.id,
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
    facts = nil
    if subject_condition_group.conditions.empty?
      assets = created_assets[subject_condition_group.id]
    end
    if action_type == 'selectAsset'
      asset_group.add_assets(asset)
    end
    if action_type == 'updateService'
      asset.update_attributes(:mark_to_update => true)
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
        asset_group.add_assets(assets)
      end
      assets = created_assets[subject_condition_group.id]

      created_assets[subject_condition_group.id].each_with_index do |created_asset, i|
        created_asset.generate_barcode(i)
        facts = generate_facts(created_assets, asset_group, step, asset).map(&:dup)
        created_asset.add_facts(facts)
      end
    end
    if action_type == 'addFacts'
      msg = 'You cannot add facts to an asset not present in the conditions'
      raise Step::UnknownConditionGroup, msg if assets.compact.length==0
      assets.each do |asset|
        facts = generate_facts(created_assets, asset_group, step, asset).map(&:dup)
        asset.add_facts(facts)
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
