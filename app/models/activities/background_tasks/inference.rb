require 'inference_engines/cwm/step_execution'

class Activities::BackgroundTasks::Inference < Activities::BackgroundTasks::BackgroundStep

  def process
    inferences = InferenceEngines::Cwm::StepExecution.new(
      :step => self,
      :asset_group => asset_group,
      :created_assets => {},
      :step_types => [step_type]
    )
    ActiveRecord::Base.transaction do
      inferences.run
    end
  end

end
