require 'inference_engines/cwm/step_execution'

class BackgroundSteps::Inference < BackgroundSteps::BackgroundStep

  def assets_compatible_with_step_type
    Rails.configuration.enable_reasoning && (activity.step_types.for_reasoning.count > 0)
  end

  def execute_actions
    type = StepType.find_or_create_by(:name => 'Reasoning...')
    type.update_attributes(:superceded_by_id => -1)
    update_attributes!({
      :state => 'running',
      :step_type => type,
      :asset_group => AssetGroup.create!(:assets => asset_group.assets)
    })
    background_job
  end

  def background_job
    inferences = InferenceEngines::Cwm::StepExecution.new(
      :step => self, 
      :asset_group => asset_group,
      :created_assets => {},
      :step_types => activity.step_types.for_reasoning
    )    
    ActiveRecord::Base.transaction do
      inferences.run
    end
    update_attributes!(:state => 'complete')
    asset_group.touch
  ensure
    update_attributes!(:state => 'error') unless state == 'complete'
    asset_group.touch
  end

  handle_asynchronously :background_job  
end