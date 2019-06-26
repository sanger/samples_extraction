require 'rails_helper'
RSpec.describe 'Steps::Stoppable' do
  let(:activity) { create(:activity)}
  let(:asset_group) { create(:asset_group) }
  let(:step_type) { create(:step_type)}

  let(:previous_steps) {
    2.times.map{
      create(:step, state: 'complete', activity: activity, asset_group: asset_group, step_type: step_type)
    }
  }
  let(:next_steps) {
    2.times.map{
      create(:step, state: nil, activity: activity, asset_group: asset_group, step_type: step_type)
    }
  }

  let(:step) { create(:step, state: previous_state, activity: activity, asset_group: asset_group, step_type: step_type)}

  let(:do_action) {
    steps = [previous_steps, step, next_steps].flatten
    step.update_attributes(state: state)
    steps.each(&:reload)
  }

  context 'when a step is stopped' do
    let(:state) { 'stopping' }
    context 'but the step was already completed before' do
      let(:previous_state) { 'complete'}
      before do
        do_action
      end
      it 'stops any other steps after this step' do
        expect(next_steps.all?{|s| s.state == 'stop'}).to eq(true)
      end
      it 'does not stop any steps before this step' do
        expect(previous_steps.all?{|s| s.state == 'stop'}).to eq(false)
      end
      it 'rolls back the state of the step to complete because we cannot stop a step that has already been applied' do
        expect(step.state).to eq('complete')
      end
    end
    context 'when the step was not completed before' do
      let(:previous_state) { nil }
      before do
        asset = create :asset
        step.operations << create(:operation, action_type: 'create_assets', object: asset.uuid, :cancelled? => false)
        do_action
      end

      it 'stops any other steps after this step' do
        expect(next_steps.all?{|s| s.state == 'stop'}).to eq(true)
      end
      it 'does not stop any steps before this step' do
        expect(previous_steps.all?{|s| s.state == 'stop'}).to eq(false)
      end
      it 'performs cancelling of the operations for this step' do
        expect(step.operations.all?(&:cancelled?)).to eq(true)
      end
      it 'stops this step' do
        expect(step.state).to eq('stop')
      end
    end
  end
  context 'when a step is continued' do
    let(:state) { 'continuing' }
    let(:next_steps_stopped) {
      2.times.map{
        create(:step, state: 'stop', activity: activity, asset_group: asset_group, step_type: step_type)
      }
    }
    let(:next_steps_not_stopped) {
      2.times.map{
        create(:step, state: 'complete', activity: activity, asset_group: asset_group, step_type: step_type)
      }
    }
    let(:next_steps) { [next_steps_stopped, next_steps_not_stopped].flatten}

    context 'when the step was stopped before' do
      let(:previous_state) { 'stop' }
      before do
        do_action
      end

      it 'continues this step' do
        expect(step.state).to eq('complete')
      end
      it 'continues with any other stopped steps after this step' do
        expect(next_steps_stopped.all?{|s| s.state == nil}).to eq(true)
      end
      it 'does not continue with any not stopped steps after this step' do
        expect(next_steps_not_stopped.all?{|s| s.state == 'complete'}).to eq(true)
      end
      it 'does not change the state of previous steps' do
        expect(previous_steps.all?{|s| s.state == 'complete'}).to eq(true)
      end
    end
    context 'when the step was not stopped before' do
      let(:previous_state) { nil }
      before do
        do_action
      end

      it 'does not continue any other stopped steps after this step' do
        expect(next_steps_stopped.all?{|s| s.state == 'stop'}).to eq(true)
      end
      it 'does not continue with any not stopped steps after this step' do
        expect(next_steps_not_stopped.all?{|s| s.state == 'complete'}).to eq(true)
      end
      it 'does not change the state of previous steps' do
        expect(previous_steps.all?{|s| s.state == 'complete'}).to eq(true)
      end
    end
  end
end
