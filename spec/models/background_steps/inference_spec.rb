require 'rails_helper'

RSpec.describe 'Inference' do
  context '#execute_actions' do
  	context 'when there is no error' do
  		setup do
  			execution = double('step_execution')
  			allow(execution).to receive(:run)
  			allow(InferenceEngines::Cwm::StepExecution).to receive(:new).and_return(execution)  			
  		end
  		let(:inference) { create :inference }

  		it 'changes the status to complete' do
  			inference.execute_actions
  			expect(inference.state).to eq('complete')
  		end

  		it 'executes the rest of next steps' do
  			inferences = 5.times.map{ create :inference }
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