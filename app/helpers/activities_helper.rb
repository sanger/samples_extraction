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
      createUrl: activity_step_types_path(@activity, st),
      name: st.name
    }
    end    
  end

  def step_type_templates_data
    @step_types.select{|s| s.step_template }.each do |st|
      {
        createUrl: activity_step_types_path(@activity, st),
        name: st.name,
        id: "step-type-id-<%= rand(9999).to_s %>-<%= st.id %>"
      }
    end    
  end

end
