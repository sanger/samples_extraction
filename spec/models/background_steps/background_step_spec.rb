require 'rails_helper'

RSpec.describe 'BackgroundStep' do
  context '#Background step' do
    let(:step) { build :background_step }
    context 'when a background step is saved' do
      it 'does not execute actions immediately' do
        allow(step).to receive(:execute_actions)
        step.save
        expect(step).not_to have_received(:execute_actions)
      end
    end

    context 'when execute_actions is called' do
      it 'sets the state to running' do
        step.execute_actions
        expect(step.state).to eq('running')
      end

      context 'when a background step is completed' do
        context 'when there was an error' do
          let(:another_step) { build :background_step }

          it 'does not execute the next step' do
            step.update_attributes(next_step: another_step)
            allow(another_step).to receive(:execute_actions)
            step.update_attributes(state: 'error')
            expect(another_step).not_to have_received(:execute_actions)
          end
        end
        context 'when there was no error in its execution' do
          context 'when it has a next step configured' do
            let(:another_step) { build :background_step }
            it 'executes the next step' do
              step.update_attributes(next_step: another_step)
              allow(another_step).to receive(:execute_actions)
              step.update_attributes(state: 'complete')
              expect(another_step).to have_received(:execute_actions)
            end
          end
          context 'when it has several steps configured' do
            let(:my_steps) { 5.times.map{build :background_step}}
            it 'executes all steps until the last one' do
              my_steps.reverse.reduce(nil) do |memo, step|
                step.update_attributes(next_step: memo)
                allow(step).to receive(:execute_actions) do
                  step.update_attributes(state: 'complete')
                end
                step
              end
              my_steps.first.execute_actions
              expect(my_steps.last).to have_received(:execute_actions)
            end
          end
          context 'when it does not have a next step' do
            it 'does not execute the next step' do
              expect{step.update_attributes(state: 'complete')}.not_to raise_error
            end
          end
        end
      end
    end
  end
end
