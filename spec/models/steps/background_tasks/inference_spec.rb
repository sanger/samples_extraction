require 'rails_helper'

RSpec.describe Steps::BackgroundTasks::Inference do
  context '#execute_actions' do
    let(:activity) { create(:activity, state: 'running')}
    let(:execution) { double('step_execution') }
    let(:inference) { create :inference, activity: activity }

    before do
      allow(InferenceEngines::Cwm::StepExecution).to receive(:new).and_return(execution)
    end
    context 'when there is an error' do
      before do
        allow(execution).to receive(:run).and_raise(StandardError)
      end
      it 'changes the status to error' do
        expect{inference.execute_actions}.to raise_error(StandardError)
        expect(inference.state).to eq('error')
      end
      it 'adds an output value explaining the error' do
        expect{inference.execute_actions}.to raise_error(StandardError)
        expect(inference.output.nil?).to eq(false)
      end
    end
  	context 'when there is no error' do
  		before do
  			allow(execution).to receive(:run)
  		end

  		it 'changes the status to complete' do
  			inference.execute_actions
  			expect(inference.state).to eq('complete')
  		end

  		it 'executes the rest of next steps' do
  			inferences = 5.times.map{ create :inference, activity: activity }
  			inferences.reverse.reduce(nil) do |memo, step|
  				id = (memo && memo.id) || nil
  				step.update_attributes(next_step_id: id)
  				step
  			end
  			inferences.first.execute_actions
  			inferences.each(&:reload)
  			inferences.each {|i| expect(i.state).to eq('complete')}
  		end
  	end
  end
end
