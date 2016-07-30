require 'rails_helper'

RSpec.describe StepType, type: :model do
  describe '#compatible_with' do
    setup do
    end

    describe 'using data from database' do
      describe 'matching one asset' do
        setup do
          @step_type=FactoryGirl.create :step_type
          @cg1=FactoryGirl.create(:condition_group, {:name => 'p'})
          @step_type.condition_groups << @cg1
          @cg1.conditions << FactoryGirl.create(:condition, {
            :predicate => 'is', :object => 'Tube'})
          @cg1.conditions << FactoryGirl.create(:condition, {
            :predicate => 'is', :object => 'Full'})


          @asset = FactoryGirl.create :asset
        end

        it 'is compatible with a totally compatible asset' do
          @asset.facts << FactoryGirl.create(:fact, :predicate => 'is', :object => 'Tube')
          @asset.facts << FactoryGirl.create(:fact, :predicate => 'is', :object => 'Full')

          assert_equal true, @step_type.compatible_with?(@asset)
        end

        it 'is incompatible with a partially compatible asset' do
          @asset.facts << FactoryGirl.create(:fact, :predicate => 'is', :object => 'Tube')

          assert_equal false, @step_type.compatible_with?(@asset)
        end

        it 'is incompatible with a partially incompatible asset' do
          @asset.facts << FactoryGirl.create(:fact, :predicate => 'is', :object => 'Tube')
          @asset.facts << FactoryGirl.create(:fact, :predicate => 'is', :object => 'Empty')

          assert_equal false, @step_type.compatible_with?(@asset)
        end

        it 'is not compatible with an incompatible asset' do
          @asset.facts << FactoryGirl.create(:fact, :predicate => 'is', :object => 'Rack')

          assert_equal false, @step_type.compatible_with?(@asset)
        end

        describe "with special configuration" do
          describe "related with cardinality" do
            setup do
              @assets = 5.times.map{|i| FactoryGirl.create :asset, {:facts => [
                  FactoryGirl.create(:fact, :predicate => 'is', :object => 'Tube'),
                  FactoryGirl.create(:fact, :predicate => 'is', :object => 'Full')
                ]}}
            end

            it 'is compatible with any number of assets with no cardinality check' do
              @cg1.cardinality = nil

              assert_equal true, @step_type.compatible_with?(@assets)
            end

            it 'is compatible when number of assets is below the maximum cardinality' do
              @cg1.cardinality = 10
              assert_equal true, @step_type.compatible_with?(@assets)
            end

            it 'is compatible when number of assets is equal to the maximum cardinality' do
              @cg1.cardinality = 5
              assert_equal true, @step_type.compatible_with?(@assets)
            end

            it 'is incompatible when number of assets overpasses the maximum cardinality' do
              @cg1.cardinality = 4
              assert_equal false, @step_type.compatible_with?(@assets)
            end

          end
        end
      end
    end

    describe 'using rules loaded in N3' do

      it '#every_condition_group_satisfies_cardinality' do
      end
    end
  end
end
