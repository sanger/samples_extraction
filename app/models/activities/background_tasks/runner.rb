require 'inference_engines/runner/step_execution'

class Activities::BackgroundTasks::Runner < Activities::BackgroundTasks::BackgroundStep

  def process
    runner = InferenceEngines::Runner::StepExecution.new(
      :step => self, 
      :asset_group => asset_group,
      :created_assets => {},
      :step_types => [step_type]
    )
    ActiveRecord::Base.transaction do
      runner.run
    end
  end

end
