require 'rails_helper'

RSpec.describe Step, type: :model do
  Struct.new('FakeFact', :predicate, :object)

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

    describe 'when creating a new step' do
      it 'raises an exception if assets are not compatible with step_type' do
        @cg1.update_attributes(:cardinality => 1)
        expect{
          @step = FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})
          }.to raise_error(ActiveRecord::RecordNotSaved)
      end
    end

    describe 'with unselectAsset action type' do
      setup do
        @action = FactoryGirl.create(:action, {:action_type => 'addFacts',
          :predicate => 'is', :object => 'Empty', :subject_condition_group => @cg1})
        @step_type.actions << @action
      end

      it 'unselects elements from condition group' do
        @cg1.update_attributes(:keep_selected => false)

        @asset_group.assets.reload
        assert_equal true, @tubes.all?{|tube| @asset_group.assets.include?(tube)}

        @step = FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

        assert_equal false, @tubes.any?{|tube| @asset_group.assets.include?(tube)}
      end
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

          it 'connects 1 to N if cardinality is set to 1 in the subject condition group' do
            @asset_group.update_attributes(:assets => [@tubes.first, @racks].flatten)
            @cg1.update_attributes(:cardinality => 1)

            @step = FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @racks.each do |rack|
              assert_equal true, @tubes.first.has_fact?(Struct::FakeFact.new(@action.predicate,
                  rack.relation_id))
            end
            assert_equal false, @tubes.last.has_fact?(Struct::FakeFact.new(
              @action.predicate,
              @racks.first.relation_id))
          end

          it 'connects N to 1 if cardinality is set to 1 in the object condition group' do
            @asset_group.update_attributes(:assets => [@tubes, @racks.first].flatten)
            @cg2.update_attributes(:cardinality => 1)

            @step = FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @tubes.each do |tube|
              assert_equal true, tube.has_fact?(Struct::FakeFact.new(@action.predicate,
                  @racks.first.relation_id))
            end
            assert_equal false, @tubes.first.has_fact?(Struct::FakeFact.new(@action.predicate,
              @racks.last.relation_id))
          end

          it 'connects 1 to 1 if cardinality is set to 1 in both subject and object condition groups' do
            @asset_group.update_attributes(:assets => [@tubes.first, @racks.first].flatten)
            @cg1.update_attributes(:cardinality => 1)
            @cg2.update_attributes(:cardinality => 1)

            @step = FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

            @tubes.each(&:reload)
            @racks.each(&:reload)

            assert_equal true, @tubes.first.has_fact?(Struct::FakeFact.new(@action.predicate,
              @racks.first.relation_id))
          end

          it 'connects N to N if no cardinality is set' do
            @asset_group.update_attributes(:assets => [@tubes, @racks].flatten)

            @step = FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @tubes.each do |tube|
              @racks.each do |rack|
                assert_equal true, tube.has_fact?(Struct::FakeFact.new(@action.predicate,
                  rack.relation_id))
              end
            end
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
        describe 'relating different condition groups' do
          setup do
            # Something like removeFact(?tube :relatesTo ?rack)
            @action = FactoryGirl.create(:action, {:action_type => 'removeFacts',
              :predicate => 'relatesTo', :subject_condition_group => @cg1,
              :object_condition_group => @cg2})
            @step_type.actions << @action
            @tubes.first.facts << FactoryGirl.create(:fact, {
              :predicate => 'relatesTo', :object => @racks.first.relation_id,
              :literal => false})
          end

          it 'removes the link between both assets' do
            assert_equal 1, @tubes.first.facts.select{|f| f.predicate == 'relatesTo'}.length

            @asset_group.update_attributes(:assets => [@tubes.first, @racks.first].flatten)
            FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

            @tubes.each(&:reload)
            @racks.each(&:reload)
            assert_equal 0, @tubes.first.facts.select{|f| f.predicate == 'relatesTo'}.length
          end
          describe 'relating several assets' do
            it 'removes the link between all assets' do
              @tubes.each do |tube|
                @racks.each do |rack|
                  tube.facts << FactoryGirl.create(:fact, {
                    :predicate => 'relatesTo', :object => rack.relation_id,
                    :literal => false})
                end
              end

              @tubes.each(&:reload)
              @racks.each(&:reload)

              @tubes.each do |tube|
                assert_equal true, (tube.facts.select{|f| f.predicate == 'relatesTo'}.length>0)
              end

              FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

              @tubes.each(&:reload)
              @racks.each(&:reload)

              @tubes.each do |tube|
                assert_equal 0, tube.facts.select{|f| f.predicate == 'relatesTo'}.length
              end
            end

            it 'removes the link just between the matched assets' do
              @tubes.each do |tube|
                tube.facts << FactoryGirl.create(:fact, {
                 :predicate => 'relatesTo', :object => @tubes.first.relation_id,
                 :literal => false})
              end

              @racks.each do |rack|
                rack.facts << FactoryGirl.create(:fact, {
                 :predicate => 'relatesTo', :object => @racks.first.relation_id,
                 :literal => false})
              end

              @tubes.each(&:reload)
              @racks.each(&:reload)

              @tubes.each do |tube|
                assert_equal true, (tube.facts.select{|f| f.predicate == 'relatesTo'}.length>0)
              end

              @racks.each do |rack|
                assert_equal true, (rack.facts.select{|f| f.predicate == 'relatesTo'}.length>0)
              end

              FactoryGirl.create(:step, {:step_type =>@step_type, :asset_group => @asset_group})

              @tubes.each(&:reload)
              @racks.each(&:reload)

              @tubes.each do |tube|
                assert_equal 0, tube.facts.select{|f| f.predicate == 'relatesTo'}.length
              end

              @racks.each do |rack|
                assert_equal 1, rack.facts.select{|f| f.predicate == 'relatesTo'}.length
              end

            end

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
