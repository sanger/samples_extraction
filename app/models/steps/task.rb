module Steps::Task
  def process
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
        assets_for_printing = assets_for_printing.to_a.concat(updates.assets_for_printing)
      end
      if assets_for_printing.length > 0
        AssetGroup.new(assets: assets_for_printing).print(user.printer_config, user.username)
      end
    end
  end
end
