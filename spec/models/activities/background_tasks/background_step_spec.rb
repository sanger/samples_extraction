require 'rails_helper'

describe Activities::BackgroundTasks::BackgroundStep do

  def build_instance
    asset_group = build :asset_group
    build :background_step, asset_group: asset_group
  end

  it_behaves_like 'background step'
end
