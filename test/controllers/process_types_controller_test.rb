require 'test_helper'

class ProcessTypesControllerTest < ActionController::TestCase
  setup do
    @process_type = process_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:process_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create process_type" do
    assert_difference('ProcessType.count') do
      post :create, process_type: { name: @process_type.name }
    end

    assert_redirected_to process_type_path(assigns(:process_type))
  end

  test "should show process_type" do
    get :show, id: @process_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @process_type
    assert_response :success
  end

  test "should update process_type" do
    patch :update, id: @process_type, process_type: { name: @process_type.name }
    assert_redirected_to process_type_path(assigns(:process_type))
  end

  test "should destroy process_type" do
    assert_difference('ProcessType.count', -1) do
      delete :destroy, id: @process_type
    end

    assert_redirected_to process_types_path
  end
end
