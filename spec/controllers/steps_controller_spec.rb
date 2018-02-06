require 'rails_helper'

RSpec.describe StepsController, type: :controller do
  context '#execute_actions' do
    context 'when calling it in a background step' do
      let(:step) { create :background_step, 
        activity: create(:activity),
        asset_group: create(:asset_group), step_type: create(:step_type) }
      before do
        allow_any_instance_of(step.class).to receive(:process)
      end
      context 'when the step is failed' do
        before do
          step.update_attributes(state: 'error')
        end
          
        it 'reruns the step' do
          post :execute_actions, id: step.id
          step.reload
          expect(step.state).to eq('complete')
          expect(response.status).to eq(302)
        end
      end

      context 'when the step is not failed' do
        it 'ignores the call to the action' do
          post :execute_actions, id: step.id
          step.reload
          expect(step.state).not_to eq('complete')
          expect(response.status).to eq(500)          
        end
      end
    end
  end
end
