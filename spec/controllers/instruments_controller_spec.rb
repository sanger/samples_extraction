require 'rails_helper'

RSpec.describe InstrumentsController, type: :controller do
  setup do
    @instrument = FactoryGirl.create :instrument
  end

  it "should get index" do
    get :index
    assert_response :success
  end

  it "should get new" do
    get :new
    assert_response :success
  end

  it "should create instrument" do
    expect{
      post :create,  { instrument: @instrument.attributes}
    }.to change{ Instrument.count }.by(1)

    assert_redirected_to instrument_path(assigns(:instrument))
  end

  it "should show instrument" do
    get :show,  { id: @instrument}
    assert_response :success
  end

  it "should get edit" do
    get :edit,  { id: @instrument}
    assert_response :success
  end

  it "should update instrument" do
    patch :update,  { id: @instrument, instrument: @instrument.attributes}
    assert_redirected_to instrument_path(assigns(:instrument))
  end

  it "should destroy instrument" do
    expect{
      delete :destroy,  { id: @instrument}
    }.to change{ Instrument.count }.by(-1)

    assert_redirected_to instruments_path
  end
end
