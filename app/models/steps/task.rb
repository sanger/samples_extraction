require 'inference_engines/runner/step_execution'
module Steps::Task
  def process
    step_execution = StepExecution.new(step: self, asset_group: asset_group)
    updates = step_execution.plan
    return stop! unless apply_changes(updates)
    assets_for_printing = updates.assets_for_printing

    unless step_type.step_action.nil? || step_type.step_action.empty?
      runner = InferenceEngines::Runner::StepExecution.new(
        :step => self,
        :asset_group => asset_group,
        :created_assets => {},
        :step_types => [step_type]
      )
      updates = runner.plan
      return stop! unless apply_changes(updates)
      assets_for_printing = assets_for_printing.to_a.concat(updates.assets_for_printing)
    end
    if assets_for_printing.length > 0
      AssetGroup.new(assets: assets_for_printing).print(user.printer_config, user.username)
    end
  end

  def apply_changes(updates)
    reload
    return false if stopped?
    updates.apply(self)
    true
  end
end
