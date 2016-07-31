require 'rails_helper'
require 'support_n3'
RSpec.describe SupportN3 do
  setup do
    @step_type = FactoryGirl.create :step_type
  end

  def validates_parsed(obj)
    obj.each do |class_instance, instances_list|
      assert_equal instances_list.length, class_instance.send(:count)
      class_instance.send(:all).each_with_index do |instance, i|
        instances_list[i].each do |k,v|
          assert_equal v, instance.send(k)
        end
      end
    end
  end

  def validates_rule_with(parsed_obj)
    rule=RSpec.current_example.metadata[:description]
    SupportN3.parse_string(rule, {}, @step_type)
    validates_parsed(parsed_obj)
  end

  it 'parses correct N3 files' do
    SupportN3.parse_file("lib/assets/graph3.n3")
  end

  describe "parses individual rules generating the right content" do
    describe "with rules that remove facts" do
      it '{?x :a :Tube .} => { :step :removeFacts {?x :has :RNA .}.}.' do
        validates_rule_with({
          ConditionGroup => [{:name => 'x',
            :step_type => @step_type, :cardinality => nil,
            :keep_selected => true}],
          Condition => [{:predicate => 'a', :object => 'Tube'}],
          Action => [{:action_type => 'removeFacts',
                     :predicate => 'has', :object => 'RNA',
                     :object_condition_group_id => nil, :step_type_id => @step_type.id}]})
        assert_equal ConditionGroup.first, Condition.first.condition_group
        assert_equal ConditionGroup.first, Action.first.subject_condition_group
      end
    end

    describe "with rules that create new assets" do
      it '{?z :has :Content .} => {:step :createAsset {?y :a :Rack .}.}.' do
        validates_rule_with({
          ConditionGroup => [
            {:name => 'z',:step_type => @step_type, :cardinality => nil,
            :keep_selected => true},
            {:name => 'y',:step_type => nil, :cardinality => nil,
            :keep_selected => true}],
          Condition => [{:predicate => 'has', :object => 'Content'}],
          Action => [{:action_type => 'createAsset',
                     :predicate => 'a', :object => 'Rack',
                     :object_condition_group => nil,
                     :step_type_id => @step_type.id}]})

        z = ConditionGroup.find_by_name('z')
        y = ConditionGroup.find_by_name('y')
        assert_equal y, Action.first.subject_condition_group
        assert_equal z, Condition.first.condition_group
      end
    end

    describe "with rules that check cardinality" do
      it '{?a :maxCardinality """96""" . ?a :is :Tube . }=>{ :step :addFacts {?a :has :Capacity .}.}.' do
        validates_rule_with({
          ConditionGroup => [
            {:name => 'a',:step_type => @step_type, :cardinality => 96,
            :keep_selected => true}],
          Condition => [{:predicate => 'is', :object => 'Tube'}],
          Action => [{:action_type => 'addFacts',
                     :predicate => 'has', :object => 'Capacity',
                     :object_condition_group => nil,
                     :step_type_id => @step_type.id}]})
        a = ConditionGroup.find_by_name('a')
        assert_equal a, Action.first.subject_condition_group
        assert_equal a, Condition.first.condition_group
      end
    end

    describe "with rules that unselect assets" do
      it '{?a :is :Tube . }=>{ :step :unselectAsset ?a . :step :addFacts {?a :is :Full.}.}.' do
        validates_rule_with({
          ConditionGroup => [
            {:name => 'a',:step_type => @step_type, :cardinality => nil,
            :keep_selected => false}],
          Condition => [{:predicate => 'is', :object => 'Tube'}],
          Action => [{:action_type => 'addFacts',
                     :predicate => 'is', :object => 'Full',
                     :object_condition_group => nil,
                     :step_type_id => @step_type.id}
                    ]})
        a = ConditionGroup.find_by_name('a')
        assert_equal a, Action.first.subject_condition_group
      end
    end

    describe "with rules that create a relation between two matches" do

      it '{?p :is :Tube . ?q :is :TubeRack.} => {:step :addFacts {?p :transferTo ?q.}.}.' do
        validates_rule_with({
          ConditionGroup => [{:name => 'p',:step_type => @step_type,
            :cardinality => nil, :keep_selected => true},
            {:name => 'q', :step_type => @step_type,
              :cardinality => nil, :keep_selected => true}],
          Condition => [{:predicate => 'is', :object=> 'Tube'},
            {:predicate => 'is', :object => 'TubeRack'}],
          Action => [{:action_type => 'addFacts',
                      :predicate => 'transferTo',
                      :step_type_id => @step_type.id,
                      :object => 'q'}]
          })
        p= ConditionGroup.find_by_name('p')
        q= ConditionGroup.find_by_name('q')
        assert_equal p, Action.first.subject_condition_group
        assert_equal q, Action.first.object_condition_group
      end

      it '{ ?p :is :Tube2D . } => {?step :addFacts { ?p :inRack ?rack .} .?step :createAsset {
          ?rack :is :TubeRack .
          ?rack :maxCardinality """1""".
        } .}.' do
        validates_rule_with({
          ConditionGroup => [
            {:name => 'p',:step_type => @step_type, :cardinality => nil,
            :keep_selected => true},
            {:name => 'rack',:step_type => nil, :cardinality => 1,
            :keep_selected => true}],
          Condition => [
            {:predicate => 'is', :object => 'Tube2D'}
          ],
          Action => [{:action_type => 'createAsset',
                     :predicate => 'is', :object => 'TubeRack',
                     :object_condition_group => nil,
                     :step_type_id => @step_type.id},
                     {:action_type => 'addFacts',
                     :predicate => 'inRack', :object => 'rack',
                     :step_type_id => @step_type.id}
                     ]})

          p = ConditionGroup.find_by_name('p')
          q = ConditionGroup.find_by_name('rack')
          ac = Action.find_by_action_type('createAsset')
          af = Action.find_by_action_type('addFacts')
          assert_equal q, ac.subject_condition_group
          assert_equal p, af.subject_condition_group
          assert_equal q, af.object_condition_group
      end
    end
  end
end
