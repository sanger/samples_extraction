require 'rails_helper'

describe Steps::BackgroundTasks::BackgroundTask do

  let(:user) { create :user, username: 'test'}
  def build_instance
    asset_group = build :asset_group
    build :background_task, asset_group: asset_group
  end

  def create_instance(step_type, activity, group)
    create(:background_task, step_type: step_type, activity: activity, asset_group: group, user: user)
  end

  it_behaves_like 'background task'

  context 'a background task with some changes defined' do
    let(:step_type) {
      create(:step_type,
        step_action: step_action,
        condition_groups: [cg],
        actions: [
          create(:action, action_type: 'createAsset', predicate: 'a', object: 'Tube',
            subject_condition_group: cg2)
        ]
      )
    }
    let(:cg) { create :condition_group, conditions: [ create(:condition, predicate: 'a', object: 'Plate')] }
    let(:cg2) { create :condition_group }
    let(:group) { create :asset_group, assets: [asset] }
    let(:activity) { create :activity }
    let(:asset) { create :asset, facts: [ create(:fact, predicate: 'a', object: 'Plate')] }

    context 'when the step type does not have a step action' do
      let(:step_action) { nil }
      it 'runs the rule defined by the step type' do
        asset.reload

        step = create_instance(step_type, activity, group)
        expect{
          step.execute_actions
        }.to change{Asset.all.count}.by(1)
      end
    end
    context 'when the step type does have a step action' do
      let(:step_action) { 'some_action' }
      context 'when the step action runs correctly' do
        let(:valid_changes) { FactChanges.new.tap{|update| update.create_assets(["?p"])}}
        let(:correct_execution) {
          execution = double('step_execution')
          allow(execution).to receive(:plan).and_return(valid_changes)
          execution
        }
        before do
          allow(InferenceEngines::Runner::StepExecution).to receive(:new).and_return(correct_execution)
        end

        it 'runs the rule defined by the step type and the actions for the step action' do
          asset.reload

          step = create_instance(step_type, activity, group)
          expect{
            step.execute_actions
          }.to change{Asset.all.count}.by(2)
        end
      end
      context 'when the step works fine but the step action fails' do
        let(:failable_execution) {
          execution = double('step_execution')
          allow(execution).to receive(:plan).and_raise(StandardError)
          execution
        }

        before do
          allow(InferenceEngines::Runner::StepExecution).to receive(:new).and_return(failable_execution)
        end

        it 'does not perform any changes in database' do
          asset.reload

          expect(Asset.all.count).to eq(1)

          step = create_instance(step_type, activity, group)
          expect{
            step.execute_actions
          }.not_to raise_error
          expect(Asset.all.count).to eq(1)
        end
      end
    end
  end
end
