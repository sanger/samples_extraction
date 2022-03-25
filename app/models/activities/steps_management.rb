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
    # @todo This could be moved to the relationship
    compatible_step_types = step_types.not_for_reasoning.includes(condition_groups: :conditions).distinct.select do |step_type|
      step_type.compatible_with?(assets, required_assets)
    end.uniq
    in_progress_step_type_ids = steps.in_progress.group(:step_type_id).pluck(:step_type_id)
    in_progress_step_type = compatible_step_types.detect { |stype| in_progress_step_type_ids.include?(stype.id) }
    in_progress_step_type.nil? ? compatible_step_types : [in_progress_step_type]
  end

  def step_types_active
    step_types_for(asset_group.assets)
  end
end
