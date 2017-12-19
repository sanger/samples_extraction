require 'inference_engines/cwm/step_execution'

class BackgroundSteps::Inference < BackgroundSteps::BackgroundStep

  def execute_actions
    update_attributes!({
      :state => 'running',
      :step_type => step_type,
      :asset_group => AssetGroup.create!(:assets => asset_group.assets)
    })
    background_job
  end

  def output_error(exception)
    [exception.message, Rails.backtrace_cleaner.clean(exception.backtrace)].flatten.join("\n")
  end

  def background_job
    @error = nil
    begin
      inferences = InferenceEngines::Cwm::StepExecution.new(
        :step => self, 
        :asset_group => asset_group,
        :created_assets => {},
        :step_types => [step_type]
      )
      ActiveRecord::Base.transaction do
        inferences.run
      end
    rescue StandardError => e 
      @error = e
    else
      update_attributes!(:state => 'complete')
    end
  ensure
    update_attributes!(:state => 'error', output: output_error(@error)) unless state == 'complete'
    asset_group.touch
  end

  handle_asynchronously :background_job  
end