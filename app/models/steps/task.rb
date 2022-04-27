require 'inference_engines/runner/step_execution'
module Steps::Task # rubocop:todo Style/Documentation
  def process
    if operations.count > 0
      remake_me
      updates = FactChanges.new
    else
      # StepExecution here will either be InferenceEngines::Cwm::StepExecution or
      # InferenceEngines::Default::StepExecution depending on the configuration
      # parameter Rails.configuration.inference_engine which appears to be set to
      # Default.
      step_execution = StepExecution.new(step: self, asset_group: asset_group)
      updates = step_execution.plan
      return stop! unless apply_changes(updates)
    end

    assets_for_printing = updates.assets_for_printing

    unless step_type.step_action.nil? || step_type.step_action.empty?
      runner =
        InferenceEngines::Runner::StepExecution.new(
          step: self,
          asset_group: asset_group,
          created_assets: {},
          step_types: [step_type]
        )

      updates = runner.plan

      return stop! unless apply_changes(updates)

      assets_for_printing = assets_for_printing.to_a.concat(updates.assets_for_printing)
    end

    AssetGroup.new(assets: assets_for_printing).print(printer_config, user.username) if assets_for_printing.length > 0
  end

  def apply_changes(updates)
    reload
    return false if stopped?

    updates.apply(self)
    true
  end
end
