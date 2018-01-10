module BackgroundSteps

  class BackgroundStep < Step

    include QueueableJob

    after_initialize :set_step_type

    def is_background_step?
      true
    end

    def set_step_type
      update_attributes(step_type: StepType.find_or_create_by(:name => self.class.to_s )) if step_type.nil?
    end

    def asset_group_for_execution
      AssetGroup.create!(:assets => asset_group.assets)
    end

    def execute_actions_background
      update_attributes!({
        :state => 'running',
        :step_type => step_type,
        :asset_group => asset_group_for_execution
      })
      delay.background_job
    end

    def execute_actions_foreground
      update_attributes!({
        :state => 'running',
        :step_type => step_type,
        :asset_group => asset_group_for_execution
      })
      background_job      
    end

    def execute_actions
      execute_actions_background
    end

    def output_error(exception)
      [exception.message, Rails.backtrace_cleaner.clean(exception.backtrace)].flatten.join("\n")
    end

    def background_job
      assign_attributes(state: 'running', output: nil)
      @error = nil
      begin
        process
      rescue StandardError => e 
        @error = e
      else
        @error=nil
        update_attributes!(:state => 'complete')
      end
    ensure
      update_attributes!(:state => 'error', output: output_error(@error)) unless state == 'complete'
      asset_group.touch
    end

    def process
      raise NotImplementedError
    end

  end

end