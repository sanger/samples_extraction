module Steps::BackgroundTasks
  # This class needs to define the method process(). It is not implemented here
  class BackgroundTask < Step

    after_initialize :set_step_type

    def execute_actions
      update_attributes!({
        :state => 'running',
        :step_type => step_type,
        :asset_group => asset_group,
      })
      update_attributes!(job_id: delay.perform_job.id)
    end


    def is_background_step?
      true
    end

    def set_step_type
      update_attributes(step_type: StepType.find_or_create_by(:name => self.class.to_s )) if step_type.nil?
    end

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

end
