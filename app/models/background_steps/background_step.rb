module BackgroundSteps

  class BackgroundStep < Step

    after_initialize :set_step_type

    def execute_actions
      update_attributes!({
        :state => 'running',
        :step_type => step_type,
        :asset_group => asset_group_for_execution,
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
      raise NotImplementedError
    end

  end

end