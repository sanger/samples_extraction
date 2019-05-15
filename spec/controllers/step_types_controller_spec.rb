require 'rails_helper'

RSpec.describe StepTypesController, type: :controller do
  setup do
    @step_type = FactoryBot.create :step_type
  end

  it "should get index" do
    get :index
    assert_response :success
  end

  it "should get new" do
    get :new
    assert_response :success
  end

  it "should create step_type" do
    expect{
      post :create, params: { step_type: {:name => 'Test'} }
      }.to change{
        StepType.count
        }.by(1)

    assert_redirected_to step_type_url(StepType.last)
  end

  it "should show step_type" do
    get :show, params:{ id: @step_type}
    assert_response :success
  end

  it "should get edit" do
    get :show, params:{ id: @step_type }
    assert_response :success
  end

  it "should update step_type" do
    patch :update,   params: { id: @step_type, step_type: @step_type.attributes }
    assert_redirected_to step_type_url(@step_type)
  end

  it "should destroy step_type" do
    expect{
      delete :destroy, params: { id: @step_type }
      }.to change{
        StepType.count
    }.by(-1)

    assert_redirected_to step_types_url
  end

  context '#create' do
    let(:params) { {step_type: { name: 'My task' } } }
    it 'creates a new step type' do
      expect{
        post :create, params: params
      }.to change{ StepType.all.count }.by(1)
    end
    it 'redirects to the step type url' do
      post :create, params: params
      expect(response.redirect?).to eq(true)
    end
    context 'when modifying step action' do
      context 'when selecting a runner action' do
        let(:runner_name) { 'my_script.rb'}
        it 'set task_type to \"runner\"' do
          post :create, params: {
            step_type: { step_action: runner_name }
          }
          expect(StepType.last.step_action).to eq(runner_name)
          expect(StepType.last.task_type).to eq('runner')
        end
      end
      context 'when selecting a rdf action' do
        let(:runner_name) { 'my_script.n3'}
        it 'set task_type to \"cwm\"' do
          post :create, params: {
            step_type: { step_action: runner_name }
          }
          expect(StepType.last.step_action).to eq(runner_name)
          expect(StepType.last.task_type).to eq('cwm')
        end
      end
      context 'when selecting any other option' do
        it 'set task_type to \"background_step\"' do
          post :create, params: {
            step_type: { step_action: '' }
          }
          expect(StepType.last.step_action).to eq(nil)
          expect(StepType.last.task_type).to eq('background_step')
        end
      end

    end

  end

end

