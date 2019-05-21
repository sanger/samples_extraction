module Steps::ExecutionActions
  def self.included(klass)
    klass.instance_eval do
      before_create :assets_compatible_with_step_type, :unless => [:in_progress?]
      #after_update :on_complete, :if => [:completed?, :saved_change_to_state?]
    end
  end

  def can_run_now?
    !is_background_step? && !in_progress?
  end

  def is_background_step?
    false
  end

  def assets_compatible_with_step_type
    return true if asset_group.nil?
    checked_condition_groups=[], @wildcard_values = {}
    compatible = step_type.compatible_with?(asset_group_assets, nil, checked_condition_groups, wildcard_values)
    raise StandardError unless compatible
  end


  def execute_step_action
    send(step_type.step_action)
    return self
  end

  def asset_group_assets
    asset_group ? asset_group.assets : []
  end

  def process
    if activity
      activity.touch
      activity.save
    end

    step_execution = StepExecution.new(step: self, asset_group: asset_group)
    ActiveRecord::Base.transaction do |t|
      step_execution.run

    end
    update_attributes(:state => 'running')
  end

end
