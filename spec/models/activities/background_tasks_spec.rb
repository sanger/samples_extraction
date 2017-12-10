require 'rails_helper'

RSpec.describe 'BackgroundTasks' do
  class DummyBackgroundStep
    def self.create(params)
      FactoryGirl.create(:background_step)
    end
  end

  let(:activity) { create :activity }

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

  context '#do_background_tasks' do
    let(:list_of_tasks) { 5.times.map{ DummyBackgroundStep }}

    context 'when it does not have any background task defined' do
      it 'does not raise an error' do
        allow(activity).to receive(:background_tasks).and_return([])
        expect{ activity.do_background_tasks }.not_to raise_exception
      end
    end
    context 'when it has background tasks' do
      it 'executes all the background tasks' do
        my_double = double('step')
        other_double = double('step')
        allow(activity).to receive(:create_background_steps).and_return([my_double, other_double])
        expect(my_double).to receive(:execute_actions)
        expect(other_double).not_to receive(:execute_actions)
        activity.do_background_tasks
      end
    end
  end

  context '#inference_tasks' do

    it 'returns the list of inference tasks' do
      step_types = 5.times.map { create :step_type}
      reasoning_step_types = 4.times.map { create :step_type, { for_reasoning: true} }
      activity.activity_type.update_attributes(step_types: step_types.concat(reasoning_step_types))
      
      expect(activity.inference_tasks.count).to eq(reasoning_step_types.count)
    end
  end
end