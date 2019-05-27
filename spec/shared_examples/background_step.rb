require 'rails_helper'
require 'spec_helper'
shared_examples_for 'background step' do

  it_behaves_like "queueable job"

  context '#Background step' do
    let(:step) { build_instance }

    context 'when a background step is saved' do
      it 'does not execute actions immediately' do
        allow(step).to receive(:execute_actions)
        step.save
        expect(step).not_to have_received(:execute_actions)
      end
    end

    context 'when execute_actions is called' do
      context 'when the process of the background step does not fail' do
        it 'sets the state to running' do
          allow(step).to receive(:process).and_return(true)
          step.execute_actions
          expect(step.state).to eq('complete')
          expect(step.output).to eq(nil)
        end
      end
      context 'when the process of the background step fails' do
        it 'sets the state to error' do
          allow(step).to receive(:process).and_raise(StandardError, 'boom!')
          expect{ step.execute_actions }.to raise_error(StandardError)
          expect(step.state).to eq('error')
          expect(step.output).to include('boom!')
        end
      end

      context 'when re-running a background step previously failed' do
        before do
          step.update_attributes(state: 'error', output: 'previous failure!!')
        end
        context 'when the step is completed correctly' do
          before do
            allow(step).to receive(:process)
            step.execute_actions
            step.reload
          end
          it 'sets the right state to the step' do
            expect(step.state).to eq('complete')
          end
          it 'resets the output for the step' do
            expect(step.output).to eq(nil)
          end
        end
        context 'when the step fails again' do
          before do
            allow(step).to receive(:process).and_raise(StandardError, 'boom!')
            expect{ step.execute_actions }.to raise_error(StandardError)
            step.reload
          end
          it 'sets the right state to the step' do
            expect(step.state).to eq('error')
          end
          it 'sets the right output for to the step' do
            expect(step.output).to include('boom!')
          end
        end

      end
    end
  end
end
