require 'rails_helper'

describe BackgroundSteps::BackgroundStep do

  let(:activity) { create(:activity) }

  def build_instance
    asset_group = build :asset_group
    build :background_step, asset_group: asset_group, activity: activity
  end

  it_behaves_like 'background step'
end
