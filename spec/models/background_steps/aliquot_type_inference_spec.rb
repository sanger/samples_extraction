require 'rails_helper'

RSpec.describe BackgroundSteps::AliquotTypeInference do

  let(:activity) { create(:activity) }

  def build_instance
    BackgroundSteps::AliquotTypeInference.new(step_type: create(:step_type), 
      asset_group: create(:asset_group), activity: activity)
  end

  it_behaves_like 'background step'
end