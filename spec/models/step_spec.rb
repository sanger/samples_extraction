require 'rails_helper'

RSpec.describe Step, type: :model do
  describe '#execute_actions' do
    setup do
      @step_type = FactoryGirl.create :step_type
      @cg1 = FactoryGirl.create(:condition_group,{:name => 'p'})
      @cg1.conditions << FactoryGirl.create(:condition,{
        :predicate => 'is', :object => 'Tube'})
      @cg2 = FactoryGirl.create(:condition_group,{:name => 'q'})
      @cg2.conditions << FactoryGirl.create(:condition,{
        :predicate => 'is', :object => 'Rack'})
      @step_type.condition_groups << @cg1
      @step_type.condition_groups << @cg2
      @tubes = 5.times.map{|i| FactoryGirl.create(:asset, {:facts =>[
        FactoryGirl.create(:fact, :predicate => 'is', :object => 'Tube'),
        FactoryGirl.create(:fact, :predicate => 'is', :object => 'Full')
        ]})}
      @racks = 5.times.map{|i| FactoryGirl.create(:asset, {:facts =>[
        FactoryGirl.create(:fact, :predicate => 'is', :object => 'Rack'),
        FactoryGirl.create(:fact, :predicate => 'is', :object => 'Full')
        ]})}
      @assets = [@tubes, @racks].flatten
      @asset_group = FactoryGirl.create(:asset_group, {:assets => @assets})
    end

    describe 'with addFacts action_type' do
      describe 'with one action' do
        setup do
          @action = FactoryGirl.create(:action, {:action_type => 'addFacts',
            :predicate => 'is', :object => 'Empty', :subject_condition_group => @cg1})
          @step_type.actions << @action
        end

        it 'adds the fact to the matched assets' do
          @asset_group.assets.reload
          @step = FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})
          @tubes.each(&:reload)
          @tubes.each do |asset|
            assert_equal true, asset.has_fact?(@action)
          end
          @racks.each(&:reload)
          @racks.each do |asset|
            assert_equal false, asset.has_fact?(@action)
          end
        end

        describe 'relating different condition groups' do
          setup do
            @action.update_attributes(:subject_condition_group => @cg1)
            @action.update_attributes(:object_condition_group => @cg2)
          end

          it 'raises exception if cardinality is not set to 1 in at least one of the sides' do
            expect{
              FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})
            }.to raise_error(Step::RelationCardinality)
          end
        end
      end


      describe 'with several actions' do
        setup do
          @action = FactoryGirl.create(:action, {:action_type => 'addFacts',
            :predicate => 'is', :object => 'Empty'})
          @action2 = FactoryGirl.create(:action, {:action_type => 'addFacts',
            :predicate => 'is', :object => 'Red'})

          @step_type.actions << @action
          @step_type.actions << @action2
        end

        describe 'for the same condition group' do
          setup do
            @action.update_attributes(:subject_condition_group => @cg1)
            @action2.update_attributes(:subject_condition_group => @cg1)
          end
          it 'adds all the facts to all the assets of the condition group' do
            FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})
            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal true, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal false, asset.has_fact?(@action2)
            end
          end
        end

        describe 'for different condition groups' do
          setup do
            @action.update_attributes(:subject_condition_group => @cg1)
            @action2.update_attributes(:subject_condition_group => @cg2)
          end

          it 'adds the specific facts to the assets of the specific condition group' do
            FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})
            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal true, asset.has_fact?(@action)
              assert_equal false, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
          end
        end


      end
    end

    describe 'with removeFacts action_type' do
      describe 'with one action' do
        setup do
          @action = FactoryGirl.create(:action, {:action_type => 'removeFacts',
            :predicate => 'is', :object => 'Tube', :subject_condition_group => @cg1})
          @step_type.actions << @action
        end

        it 'removes the fact from the matched assets' do
          @asset_group.assets.reload
          @tubes.each do |asset|
            assert_equal true, asset.has_fact?(@action)
          end

          @step = FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})
          @tubes.each(&:reload)
          @tubes.each do |asset|
            assert_equal false, asset.has_fact?(@action)
          end
          @racks.each(&:reload)
          @racks.each do |asset|
            assert_equal false, asset.has_fact?(@action)
          end
        end
      end
      describe 'with several actions' do
        setup do
          @action = FactoryGirl.create(:action, {:action_type => 'removeFacts',
            :predicate => 'is', :object => 'Tube'})
          @action2 = FactoryGirl.create(:action, {:action_type => 'removeFacts',
            :predicate => 'is', :object => 'Full'})

          @step_type.actions << @action
          @step_type.actions << @action2
        end

        describe 'for the same condition group' do
          setup do
            @action.update_attributes(:subject_condition_group => @cg1)
            @action2.update_attributes(:subject_condition_group => @cg1)
          end
          it 'removes all the facts to all the assets of the condition group' do
            @tubes.each do |asset|
              assert_equal true, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end

            FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})
            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal false, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
          end
        end

        describe 'for different condition groups' do
          setup do
            @action.update_attributes(:subject_condition_group => @cg1)
            @action2.update_attributes(:subject_condition_group => @cg2)
          end

          it 'removes the specific facts to the assets of the specific condition group' do
            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal true, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end

            FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal false, asset.has_fact?(@action2)
            end
          end
        end

      end
    end

  end
end
