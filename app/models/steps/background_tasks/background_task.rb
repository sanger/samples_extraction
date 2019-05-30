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
      #if activity
      #  activity.touch
      #  activity.save
      #end

      step_execution = StepExecution.new(step: self, asset_group: asset_group)
      updates = step_execution.plan

      unless step_type.step_action.nil? || step_type.step_action.empty?
        runner = InferenceEngines::Runner::StepExecution.new(
          :step => self,
          :asset_group => asset_group,
          :created_assets => {},
          :step_types => [step_type]
        )
        updates.merge(runner.plan)
      end

      updates.apply(self)
      #update_attributes(:state => 'running')
    end
  end

end
