require 'spec_helper'

shared_examples_for "queueable job" do

  context 'when a background step is completed' do
    let(:step) { build_instance }
    context 'when there was an error in its execution' do
      before do
        allow(step).to receive(:execute_actions) do
          step.update_attributes(state: 'error')
        end
      end
      context 'when it has a next step configured' do
        let(:another_step) { build_instance }
        it 'does not execute the next step' do
          step.update_attributes(next_step: another_step)
          allow(another_step).to receive(:execute_actions)
          step.execute_actions
          expect(another_step).not_to have_received(:execute_actions)
        end
      end

      context 'when it has several steps configured' do
        let(:my_steps) { 5.times.map{build_instance}}
        it 'does not execute any of the steps' do
          my_steps.reverse.reduce(nil) do |memo, step|
            step.update_attributes(next_step: memo)
            allow(step).to receive(:execute_actions) do
              step.update_attributes(state: 'complete')
            end
            step
          end
          step.update_attributes(next_step: my_steps.first)
          step.execute_actions
          expect(my_steps.last).not_to have_received(:execute_actions)
        end
      end

    end
    context 'when the step is still in progress and has a next step' do
      let(:another_step) { build_instance }
      before do
        allow(another_step).to receive(:execute_actions)
        allow(step).to receive(:execute_actions) do
          step.update_attributes(state: 'in_progress')
        end
        step.update_attributes(next_step: another_step)
      end
      it 'does not execute the next step' do
        step.execute_actions
        expect(another_step).not_to have_received(:execute_actions)
      end
    end
    context 'when the step is still running and has a next step' do
      let(:another_step) { build_instance }
      before do
        allow(another_step).to receive(:execute_actions)
        allow(step).to receive(:execute_actions) do
          step.update_attributes(state: 'running')
        end
        step.update_attributes(next_step: another_step)
      end
      it 'does not execute the next step' do
        step.execute_actions
        expect(another_step).not_to have_received(:execute_actions)        
      end
    end

    context 'when there was no error in its execution' do
      context 'when it has a next step configured' do
        let(:another_step) { build_instance }
        it 'executes the next step' do
          step.update_attributes(next_step: another_step)
          allow(another_step).to receive(:execute_actions)
          step.update_attributes(state: 'complete')
          expect(another_step).to have_received(:execute_actions)
        end
      end
      context 'when it has several steps configured' do
        let(:my_steps) { 5.times.map{build_instance}}

        context 'when all the steps are correct' do
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

        context 'when one of the steps has a failure' do
          def mock_step_completion(s, state)
            allow(s).to receive(:execute_actions) do
              s.update_attributes(state: state)
            end
          end
          before do
            my_steps.reverse.reduce(nil) do |memo, step|
              step.update_attributes(next_step: memo)
              step
            end   
            mock_step_completion(my_steps[0], 'complete')
            mock_step_completion(my_steps[1], 'complete')
            mock_step_completion(my_steps[2], 'error')
            mock_step_completion(my_steps[3], 'complete')
            mock_step_completion(my_steps[4], 'complete')
          end

          it 'executes all the steps until the one that fails' do
            my_steps.first.execute_actions
            expect(my_steps[1]).to have_received(:execute_actions)
            expect(my_steps[2]).to have_received(:execute_actions)
          end
          it 'does not execute steps after the one that fails' do
            my_steps.first.execute_actions
            expect(my_steps[3]).not_to have_received(:execute_actions)
            expect(my_steps[4]).not_to have_received(:execute_actions)
          end
        end
      end
      context 'when it does not have a next step' do
        before do
          allow(step).to receive(:execute_actions) do
            step.update_attributes(state: 'complete')
          end          
        end
        it 'does not raise an error' do
          step.update_attributes(next_step: nil)
          expect{step.execute_actions}.not_to raise_error
        end
      end
    end
  end

end