require 'rails_helper'

describe Steps::BackgroundTasks::BackgroundTask do

  def build_instance
    asset_group = build :asset_group
    build :background_task, asset_group: asset_group
  end

  it_behaves_like 'background task'
end
