module Activities::StepsManagement
  def active_step
    return nil unless steps.in_progress

    steps.in_progress.first
  end

  def previous_steps
    asset_group.assets.includes(:steps).map(&:steps).concat(steps).flatten.sort { |a, b| a.id <=> b.id }.uniq
  end

  def assets
    steps.last.assets
  end

  def steps_for(assets)
    assets.includes(:steps).map(&:steps).concat(steps).flatten.compact.uniq
  end

  def step_types_for(assets, required_assets = nil)
    stypes = step_types.not_for_reasoning.includes(:condition_groups => :conditions).select do |step_type|
      step_type.compatible_with?(assets, required_assets)
    end.uniq
    stype = stypes.detect { |stype| steps.in_progress.for_step_type(stype).count > 0 }
    stype.nil? ? stypes : [stype]
  end

  def step_types_active
    step_types_for(asset_group.assets)
  end
end
