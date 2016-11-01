module StepExecution::FactActions

  def add_facts
    msg = 'You cannot add facts to an asset not present in the conditions'
    raise Step::UnknownConditionGroup, msg if changed_assets.compact.length==0
    @changed_facts = generate_facts
    changed_assets.each do |asset|
      asset.add_facts(changed_facts.map(&:dup), position) do |fact|
        create_operation(asset, fact)
      end
    end
  end

  def remove_facts
    changed_assets.each_with_index do |asset, idx|
      @changed_facts = asset.facts.select do |f|
        ((f.predicate == action.predicate) &&
        (((action.object.nil? || (f.object == action.object))) ||
          (f.object_asset && action.object_condition_group.compatible_with?(f.object_asset))))
      end.select do |f|
        (position.nil? || f.object_asset.nil?) ? true : (position_for_asset(f.object_asset, action.object_condition_group)==position)
      end.each do |fact|
        create_operation(asset, fact)
      end
      if facts_to_destroy.nil?
        @changed_facts.each do |fact|
          fact.update_attributes(:to_remove_by => step.id)
        end
      else
        facts_to_destroy.push(@changed_facts)
      end
    end
  end

  def wildcard_facts
    if action.object_condition_group.is_wildcard?
      values = step.wildcard_values[action.object_condition_group.id][asset.id] || []
      values.map do |value|
          {
              :predicate => action.predicate,
              :object => value,
              :object_asset_id => nil,
              :literal => true
          }
      end
    end
  end

  def position_for_asset(asset, condition_group)
    positions_for_asset[asset] = {} unless positions_for_asset[asset]
    unless positions_for_asset[asset][condition_group]
      positions_for_asset[asset][condition_group] = step.step_type.position_for_assets_by_condition_group([asset])
    end
    positions_for_asset[asset][condition_group]
  end

  def generate_facts
    data = {}
    if action.object_condition_group.nil?
      data = [{:predicate => action.predicate, :object => action.object}]
    else
      if created_assets[action.object_condition_group.id].nil?
        if action.object_condition_group.is_wildcard?
          # A wildcard value might be an asset as well, not just values
          # we need to add support to them
          data = wildcard_facts
        else
          data = asset_group.assets.each_with_index.map.select do |related_asset, idx|
            # They are compatible if the object condition group is
            # compatible and if they share a common range of values of
            # values for any of the wildcard values defined
            checked_wildcards = true
            if step.wildcard_values
              checked_wildcards = step.wildcard_values.all? do |cg_id, data|
                (data[asset.id] && data[related_asset.id]) &&
                  (!(data[asset.id] & data[related_asset.id]).empty?)
              end
            end
            action.object_condition_group.compatible_with?(related_asset) && checked_wildcards
          end.map do |related_asset, idx|
            {
              :position => position_for_asset(related_asset, action.object_condition_group),
              :predicate => action.predicate,
              :object => related_asset.relation_id,
              :object_asset_id => related_asset.id,
              :literal => false

            }
          end
        end
      else
        data = created_assets[action.object_condition_group.id].each_with_index.map do |related_asset, idx|
          {
          :position => idx, #position_for_asset(related_asset, action.object_condition_group),
          :predicate => action.predicate,
          :object => related_asset.relation_id,
          :object_asset_id => related_asset.id,
          :literal => false
          }
        end
      end
    end
    in_progress = step.in_progress? ? {:to_add_by => step.id} : {}
    data.map do |obj|
      created_fact_obj = obj.merge(in_progress)
      created_fact_obj= created_fact_obj.delete_if{|k,v| (k==:position) && (step.step_type.connect_by != 'position')}
      Fact.new(created_fact_obj)
    end
  end
end
