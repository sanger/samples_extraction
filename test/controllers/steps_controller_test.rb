require 'test_helper'

class StepsControllerTest < ActionController::TestCase
  setup do
    @controller = StepsController.new
  end

  context "when performing an activity" do
    setup do
      @user = FactoryGirl.create :user
      @user.generate_token

      session[:token] = @user.token

      @asset = FactoryGirl.create :asset, :barcode => '1111'
      @asset_group = FactoryGirl.create :asset_group
      @activity_type = FactoryGirl.create :activity_type
      @activity = FactoryGirl.create :activity, { :activity_type => @activity_type, :asset_group => @asset_group}
      @step_type = FactoryGirl.create :step_type
      @activity_type.step_types << @step_type
    end

    should "create a new step inside the activity" do

      count = Step.all.count

      post :create,  { :activity_id => @activity.id, :step_type_id => @step_type.id },
        session: { :token => @user.token}
      assert_equal Step.all.count, count + 1
    end

    context "POST /activities/:activity/step_types/:step_type/steps" do
      should "create a new step with status 'done' when no parameters are provided" do
        c = Step.all.count

        post :create, { :activity_id => @activity.id, :step_type_id => @step_type.id}
        Step.all.reload
        assert_equal Step.all.count, c+1
        assert_equal false, Step.last.in_progress?
      end

      should "create a new step with status 'in progress' when pairing parameters are provided" do
        rule = "{?p :is :Tube . ?q :is :Tube2.} => { :step :addFacts { ?p :transfer ?q.}.}."
        SupportN3.parse_string(rule, {}, @step_type)
        assets = []
        10.times.each do |i|
          asset = FactoryGirl.create :asset, {:facts =>[
            FactoryGirl.create(:fact, :predicate => 'is', :object => 'Tube')]}
          asset2 = FactoryGirl.create :asset, {:facts =>[
            FactoryGirl.create(:fact, :predicate => 'is', :object => 'Tube2')]}
          assets << asset
          assets << asset2
        end

        @asset_group.assets = assets
        barcodes_pairs = assets.map(&:barcode).each_slice(2).to_a

        pairings = {}


        @step_type.reload

        cgp = @step_type.condition_groups.first
        cgq = @step_type.condition_groups.last
        barcodes_pairs.each_with_index do |pair, index|
          pairings[index]={}
          pairings[index][cgp.id] = pair[0]
          pairings[index][cgq.id] = pair[1]
        end

        c = Step.all.count

        post :create, {:activity_id => @activity.id, :step_type_id => @step_type.id, :step => {:pairings => pairings, :state => 'in_progress'}}, session: { :token => @user.token}
        assert_equal Step.all.count, c+1
        assert_equal true, Step.last.in_progress?
        post :create, {:activity_id => @activity.id, :step_type_id => @step_type.id}
        assert_equal Step.all.count, c+1
        assert_equal false, Step.last.in_progress?
        assert_equal 10, assets.map{|a| a.facts.with_predicate('transfer')}.flatten.uniq.count
      end
    end

  end



end
