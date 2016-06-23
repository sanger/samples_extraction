require 'test_helper'

class KitTypesControllerTest < ActionController::TestCase
  setup do
    @kit_type = kit_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:kit_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create kit_type" do
    assert_difference('KitType.count') do
      post :create, kit_type: { name: @kit_type.name, process_type_id: @kit_type.process_type_id, target_type: @kit_type.target_type }
    end

    assert_redirected_to kit_type_path(assigns(:kit_type))
  end

  test "should show kit_type" do
    get :show, id: @kit_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @kit_type
    assert_response :success
  end

  test "should update kit_type" do
    patch :update, id: @kit_type, kit_type: { name: @kit_type.name, process_type_id: @kit_type.process_type_id, target_type: @kit_type.target_type }
    assert_redirected_to kit_type_path(assigns(:kit_type))
  end

  test "should destroy kit_type" do
    assert_difference('KitType.count', -1) do
      delete :destroy, id: @kit_type
    end

    assert_redirected_to kit_types_path
  end
end
