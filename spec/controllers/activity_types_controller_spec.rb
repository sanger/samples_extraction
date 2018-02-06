require 'rails_helper'

RSpec.describe ActivityTypesController, type: :controller do
  setup do
    @activity_type = FactoryGirl.create :activity_type
  end

  it "should get index" do
    get :index
    assert_response :success
  end

  it "should get new" do
    get :new
    assert_response :success
  end

  it "should create activity_type" do
    expect{
      post :create,  { activity_type: @activity_type.attributes}
    }.to change{ActivityType.count}.by(1)

    assert_redirected_to activity_type_path(assigns(:activity_type))
  end

  it "should show activity_type" do
    get :show,  { id: @activity_type }
    assert_response :success
  end

  it "should get edit" do
    get :edit,  { id: @activity_type }
    assert_response :success
  end

  it "should update activity_type" do
    patch :update,  { id: @activity_type, activity_type: @activity_type.attributes}
    assert_redirected_to activity_type_path(assigns(:activity_type))
  end

  it "should destroy activity_type" do
    expect{
      delete :destroy,  { id: @activity_type}
      }.to change{ActivityType.count}.by(-1)

    assert_redirected_to activity_types_path
  end
end
