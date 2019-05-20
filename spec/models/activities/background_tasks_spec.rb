require 'rails_helper'

RSpec.describe 'BackgroundTasks' do
  class DummyBackgroundStep
    def self.create!(params)
      @instance = FactoryBot.create(:background_step, params)
    end
    def self.update_attributes!(params)
      @instance.update_attributes!(params)
    end
  end

  let(:activity) { create :activity }
  let(:step_type) { create :step_type}
  let(:asset_group) { create :asset_group}
  let(:step) { create :step, step_type: step_type }

  context '#create_background_steps' do
    let(:list_of_tasks) { 5.times.map{ DummyBackgroundStep }}
    it 'creates the list of steps' do
      activity.create_background_steps(list_of_tasks, {})
      expect(Step.all.count).to eq(5)
    end
    it 'connects each step with the next one' do
      activity.create_background_steps(list_of_tasks, {})
      steps = Step.all
      steps.each_with_index do |s, idx|
        if ((idx+1) < steps.count)
          expect(s.next_step).to eq(steps[idx+1])
        end
      end
    end
  end

  context '#create_connected_tasks' do
    let(:list_of_tasks) { 5.times.map{ DummyBackgroundStep }}

    let(:other_step) { create :step, step_type: step_type }
    context 'when it does not have any background task defined' do
      it 'does not raise an error' do
        allow(activity).to receive(:background_tasks).and_return([])
        expect{ activity.create_connected_tasks(step, asset_group) }.not_to raise_exception
      end
    end
    context 'when it has background tasks' do
      it 'creates a list of connected tasks' do
        allow(activity).to receive(:background_tasks).and_return([Activities::BackgroundTasks::BackgroundStep])
        expect(activity.create_connected_tasks(step, asset_group).length).to eq(2)
      end
    end
  end

  context '#background_tasks' do

    it 'returns the list of inference tasks' do
      step_types = 5.times.map { create :step_type}
      reasoning_step_types = 4.times.map { create :step_type, { for_reasoning: true } }
      activity.activity_type.update_attributes(step_types: step_types.concat(reasoning_step_types))

      expect(activity.background_tasks.count).to eq(reasoning_step_types.count)
    end
  end
end
