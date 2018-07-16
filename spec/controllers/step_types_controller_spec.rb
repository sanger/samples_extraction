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
end
