require 'test_helper'

class StepsControllerTest < ActionController::TestCase
  setup do
    @step = FactoryGirl.create :step
    @controller = StepsController.new
  end

  context "when performing an activity" do
    setup do
      @asset = FactoryGirl.create :asset, :barcode => '1111'
      @activity_type = FactoryGirl.create :activity_type
      @activity = FactoryGirl.create :activity, :activity_type => @activity_type
    end

    should "create a new step inside the activity" do
      count = Step.all.count
      post :create, { :activity_id => @activity.id, :asset_barcode => ['1111']}
      assert_equal Step.all.count, count + 1
    end
  end

end
