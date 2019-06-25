require 'inference_engines/runner/step_execution'

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
    #if activity
    #  activity.touch
    #  activity.save
    #end

    ActiveRecord::Base.transaction do
      step_execution = StepExecution.new(step: self, asset_group: asset_group)
      updates = step_execution.plan
      updates.apply(self)
      assets_for_printing = updates.assets_for_printing

      unless step_type.step_action.nil? || step_type.step_action.empty?
        runner = InferenceEngines::Runner::StepExecution.new(
          :step => self,
          :asset_group => asset_group,
          :created_assets => {},
          :step_types => [step_type]
        )
        updates = runner.plan
        updates.apply(self)
        assets_for_printing = assets_for_printing.concat(updates.assets_for_printing)
      end
      if assets_for_printing.length > 0
        AssetGroup.new(assets: assets_for_printing).print(user.printer_config, user.username)
      end
    end

    update_attributes(:state => 'running')
  end

end
