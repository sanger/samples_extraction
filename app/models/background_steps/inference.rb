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
      update_attributes!(:state => 'complete')
    rescue StandardError => e
      @error = e
    end
  ensure
    unless state == 'complete'
      update_attributes!(:state => 'error', :output => @error.backtrace.join("\n"))
    end 
    asset_group.assets.each(&:touch)
    asset_group.touch
  end

end