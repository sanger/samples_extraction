require 'rails_helper'

RSpec.describe StepsController, type: :controller do
  let(:activity) { create(:activity)}
  let(:asset_group) { create(:asset_group) }
  let(:step_type) {create(:step_type)}

  before do
    session[:token] = 'mytoken'
    @user = create :user, token: session[:token]
  end

  context '#create' do
    it 'creates a new step' do
      expect {
        post :create, params: { activity_id: activity.id, step:{ asset_group_id: asset_group.id, step_type_id: step_type.id }}
      }.to change{Step.all.count}
    end
  end
  context '#update' do
    let(:step) { create :step,
      activity: activity,
      asset_group: asset_group, step_type: step_type }

    let(:event_name) { Step::EVENT_RUN }

    it 'changes the state for the step' do
      post :update, params: { id: step.id, step: {event_name: event_name} }
      step.reload
      expect(step.state).to eq('complete')
      expect(response.status).to eq(200)
    end
  end

end
