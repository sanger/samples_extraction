require 'rails_helper'

RSpec.describe KitsController, type: :controller do
  setup do
    @kit_type = FactoryBot.create :kit_type
    @kit = FactoryBot.create :kit, { :kit_type => @kit_type }
  end

  it "should get index" do
    get :index
    assert_response :success
  end

  it "should get new" do
    get :new
    assert_response :success
  end

  it "should create kit" do
    expect do
      post :create, params: { kit: @kit.attributes }
    end.to change { Kit.count }.by(1)

    assert_redirected_to kit_path(assigns(:kit))
  end

  it "should show kit" do
    get :show, params: { id: @kit }
    assert_response :success
  end

  it "should get edit" do
    get :edit, params: { id: @kit }
    assert_response :success
  end

  it "should update kit" do
    patch :update,  params: { id: @kit, kit: @kit.attributes }
    assert_redirected_to kit_path(assigns(:kit))
  end

  it "should destroy kit" do
    expect do
      delete :destroy, params: { id: @kit }
    end.to change { Kit.count }.by(-1)

    assert_redirected_to kits_path
  end
end
