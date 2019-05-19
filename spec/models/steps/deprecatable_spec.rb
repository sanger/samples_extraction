require 'rails_helper'

RSpec.describe 'Steps::Deprecatable' do
  let(:activity) { create(:activity)}
  let(:asset_group) { create(:asset_group) }
  let(:step_type) { create(:step_type)}
  context '#execute_actions' do
    let(:state) {'cancel'}
    it 'deprecates all cancelled steps created before me on step execution' do
      steps = 10.times.map{create(:step, state: state, activity: activity)}
      step = create(:step, activity: activity, asset_group: asset_group, step_type: step_type)

      expect(steps.all?{|s| s.state == state}).to eq(true)
      expect(activity.steps.count).to eq(11)
      step.execute_actions
      steps.each(&:reload)
      expect(steps.all?{|s| s.state == 'deprecated'}).to eq(true)
      expect(activity.steps.count).to eq(1)
    end
    it 'deprecates all pending steps created before me on step execution' do
      steps = 10.times.map{create(:step, state: nil, activity: activity)}
      step = create(:step, activity: activity, asset_group: asset_group, step_type: step_type)

      expect(activity.steps.count).to eq(11)
      step.execute_actions
      steps.each(&:reload)
      expect(steps.all?{|s| s.state == 'deprecated'}).to eq(true)
      expect(activity.steps.count).to eq(1)
    end

    it 'does not deprecate any steps created before me that are in my chain for next_step' do
      steps = 10.times.map{create(:step, state: nil, activity: activity, asset_group: asset_group, step_type: step_type)}
      step = create(:step, activity: activity, asset_group: asset_group, step_type: step_type, next_step: steps.last)

      expect(activity.steps.count).to eq(11)
      step.execute_actions
      steps.each(&:reload)
      expect(steps.select{|s| s.state == 'deprecated'}.count).to eq(9)
      expect(steps.select{|s| s.state == 'complete'}.count).to eq(1)
      expect(activity.steps.count).to eq(2)
    end
  end
end
