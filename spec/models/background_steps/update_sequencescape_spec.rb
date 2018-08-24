require 'rails_helper'

RSpec.describe BackgroundSteps::UpdateSequencescape do

  let(:activity) { create(:activity, state: 'running') }

  def build_instance
    asset = create(:asset)
    asset.facts << (create(:fact, predicate: 'pushTo', object: 'Sequencescape'))

    asset_group = create(:asset_group)
    asset_group.update_attributes(assets: [asset])

    BackgroundSteps::UpdateSequencescape.new(step_type: create(:step_type), 
      activity: activity,
      asset_group: asset_group)
  end

  it_behaves_like 'background step'

end