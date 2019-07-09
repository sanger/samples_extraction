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

    context 'when a step is running' do
      let(:step) { create :step,
        activity: activity,
        asset_group: asset_group, step_type: step_type }

      let(:run_step) {
        # We want to simulate that during a running process a 'stop' event is received so we
        # need 2 different calls ran asynchronously that is why one of them will be performed
        # in a different thread
        step_id = step.id
        Thread.new do
          post :update, params: { id: step_id, step: { event_name: 'run' } }
        end
      }
      it 'can be stopped' do
        step_id = step.id
        allow_any_instance_of(Step).to receive(:process) do
          post :update, params: { id: step_id, step: { event_name: 'stop' } }
        end

        run_step

        step.reload
        expect(step.pending?).to eq(true)
      end
      context 'when the step performed some changes before stopping' do

        it 'cancels all changes that were produced during running' do
          step_id = step.id
          allow_any_instance_of(Step).to receive(:process) do
            FactChanges.new.create_assets(["?p"]).apply(step)
            post :update, params: { id: step_id, step: { event_name: 'stop' } }
          end
          expect(step.operations.all?{|op| !op.cancelled?}).to eq(true)

          run_step

          step.reload
          expect(step.operations.all?{|op| op.cancelled?}).to eq(true)
          expect(step.pending?).to eq(true)
        end
      end
    end

  end

end
