module ActivitiesHelper

  def asset_types_for(assets_grouped, step_type, &block)
    created_condition_groups = []
    asset_types = []
    @assets_grouped.each do |fact_group, assets|
      fake_asset = Struct.new(:facts).new(fact_group)
      cgs=step_type.condition_groups.select do |c|
        c.compatible_with?(fake_asset)
      end
      created_condition_groups << cgs
      yield(fact_group, assets, cgs)
    end
    remaining_condition_groups =  step_type.condition_groups - created_condition_groups.flatten
    klass = Struct.new(:predicate, :object, :object_asset_id, :to_add_by, :to_remove_by)
    remaining_condition_groups.each do |remaining|
      conditions_to_facts = remaining.conditions.map do |c|
        klass.new(c.predicate, c.object, nil, nil, nil)
      end
      yield(conditions_to_facts, [], [remaining])
    end
  end

  def step_types_data
    @step_types.map do |st|
    {
      createStepUrl: Rails.application.routes.url_helpers.activity_steps_path(@activity),
      stepType: st,
      name: st.name
    }
    end
  end

  def step_types_data_for_step_types(activity, step_types)
    step_types.select{|st| st.step_template.blank? }.map do |st|
    {
      createStepUrl: Rails.application.routes.url_helpers.activity_steps_path(activity),
      stepType: st,
      name: st.name
    }
    end
  end


  def step_types_for_asset_groups_data(activity, asset_group)
    step_types = activity.step_types_for(asset_group.assets)
    {
      updateUrl: Rails.application.routes.url_helpers.activity_step_types_path(activity),
      stepTypesData: step_types_data_for_step_types(activity, step_types),
      stepTypesTemplatesData: step_type_templates_data_for_step_types(activity, step_types, asset_group)
    }
  end

  def step_types_control_data(activity)
    activity.owned_asset_groups.reduce({}) do |memo, asset_group|
      data_for_step_types = step_types_for_asset_groups_data(activity, asset_group)
      memo[asset_group.id] = data_for_step_types
      memo
    end
  end

  def steps_data
    steps_data_for_steps(@steps ? @steps.reverse : [])
  end

  def steps_data_for_steps(steps)
    steps.map do |step|
      {
        stepUpdateUrl: Rails.application.routes.url_helpers.step_path(step),
        activity: step.activity,
        asset_group: step.asset_group,
        step_type: step.step_type,
        operations: step.operations,
        username: step.user.username
      }.merge(step.attributes)
    end
  end

  def steps_without_operations_data_for_steps(steps)
    steps.map do |step|
      {
        state: step.state,
        asset_group_id: step.asset_group.id,
        step_type_id: step.step_type.id,
        step_id: step.id
      }
    end
  end

  def facts_data(facts)
    occured_predicates = []
    facts.reduce([]) do |memo, fact|
      if occured_predicates.include?(fact.predicate)
        obj = memo.select{|f| f["predicate"] == fact.predicate}.first
        obj["repeats"] = obj["repeats"] ? obj["repeats"]+1 : 0
        next memo
      end
      elem = fact.object_asset
      if elem
        obj = {"object_asset" => {
                 uuid: elem.uuid,
                 barcode: elem.barcode,
                 id: elem.id,
                 info_line: elem.info_line
               }}.merge(fact.attributes)
      else
        obj = fact.attributes
      end
      memo.push(obj)
      memo
    end
  end


  def asset_data(asset)
    asset.facts.reload
    {barcode: asset.barcode, uuid: asset.uuid, facts: facts_data(asset.facts)}
  end

  def asset_group_data(activity, asset_group)
    {
      id: asset_group.id,
      activityId: asset_group.activity_owner.id,
      lastUpdate: asset_group.updated_at,
      updateUrl: Rails.application.routes.url_helpers.activity_asset_group_path(activity, asset_group),
      condition_group_name: asset_group.condition_group_name,
      name: asset_group.display_name,
      assets_running: activity.steps.running.joins(asset_group: :assets).map(&:assets).flatten.map(&:uuid).uniq,
      assets: asset_group.assets.map{|asset| asset_data(asset)}
    }
  end

  def asset_groups_data(activity)
    activity.owned_asset_groups.reduce({}) do |memo, asset_group|
      asset_group.assets.reload
      data_for_step_types = asset_group_data(activity, asset_group)
      memo[asset_group.id] = data_for_step_types
      memo
    end
  end


  def step_type_templates_data
    @step_types.select{|s| !s.step_template.blank? }.map do |st|
      {
        createStepUrl: Rails.application.routes.url_helpers.activity_steps_path(@activity),
        stepType: st,
        name: st.name,
        id: "step-type-id-#{ rand(9999).to_s }-#{ st.id }"
      }
    end
  end

  def step_type_templates_data_for_step_types(activity, step_types, asset_group)
    step_types.select{|s| !s.step_template.blank? }.map do |st|
      {
        asset_group: asset_group,
        createStepUrl: Rails.application.routes.url_helpers.activity_steps_path(activity),
        stepType: st,
        name: st.name,
        id: "step-type-id-#{ rand(9999).to_s }-#{ st.id }"
      }
    end
  end

  def data_asset_display_for_asset_group(asset_group)
    asset_group.assets.reduce({}) do |memo, asset|
      memo[asset.uuid] = data_asset_display(asset.facts)
      next memo
      if ((asset.has_literal?('a', 'TubeRack')) || ((asset.has_literal?('a', 'Plate'))))
        memo[asset.uuid] = data_asset_display(asset.facts)
      end
      memo
    end
  end

  def data_asset_display_for_activity(activity)
    activity.owned_asset_groups.reduce({}) do |memo, asset_group|
      memo.merge(data_asset_display_for_asset_group(asset_group))
    end
  end

  def messages_for_activity(activity)
    activity.steps.failed.map{|s| {type: 'danger', msg: s.output.to_s.html_safe} }
  end

end
