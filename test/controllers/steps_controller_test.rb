require 'test_helper'

class StepsControllerTest < ActionController::TestCase
  setup do
    @controller = StepsController.new
  end

  context "when performing an activity" do
    setup do
      @user = FactoryGirl.create :user
      @user.generate_token
      @asset = FactoryGirl.create :asset, :barcode => '1111'
      @asset_group = FactoryGirl.create :asset_group
      @activity_type = FactoryGirl.create :activity_type
      @activity = FactoryGirl.create :activity, { :activity_type => @activity_type, :asset_group => @asset_group}
      @step_type = FactoryGirl.create :step_type
      @activity_type.step_types << @step_type
    end

    should "create a new step inside the activity" do

      count = Step.all.count

      post :create, params: { :activity_id => @activity.id, :step_type_id => @step_type.id }, session: { :token => @user.token}
      assert_equal Step.all.count, count + 1
    end
  end

end
