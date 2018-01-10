require 'rails_helper'

RSpec.describe BackgroundSteps::AliquotTypeInference do

  def build_instance
    BackgroundSteps::AliquotTypeInference.new(step_type: create(:step_type), asset_group: create(:asset_group))
  end

  it_behaves_like 'background step'
end