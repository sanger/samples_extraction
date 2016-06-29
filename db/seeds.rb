# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

asset=Asset.create!(:barcode => '1')

facts = [
  ['is_a', 'Tube'],
  ['is_a', 'ReceptionTube'],
  ['aliquotType', 'DNA']
].map do |a,b|
  Fact.create({ :predicate => a, :object => b})
end

activity_type = ActivityType.create
kit_type = KitType.create(:activity_type => @activity_type)
kit = Kit.create( {:kit_type => @kit_type, :barcode => 1111})

step_type = StepType.create(:name => 'Step B')
step_type2 = StepType.create(:name => 'Step A')

step_type.activity_types << activity_type
step_type2.activity_types << activity_type

condition_group = ConditionGroup.create(:step_type => step_type)

conditions = [
  ['is_a', 'ReceptionTube'],
  ['aliquotType', 'DNA']
].map do |a,b|
  Condition.create({
    :predicate => a, :object => b, :condition_group_id => condition_group.id})
end


asset.facts << facts
activity = Activity.create(:activity_type => activity_type)

activity_type.activities << activity

Step.create({
  :step_type_id => step_type2.id,
  :activity_id => activity.id,
  :asset_id => asset.id
})


RDF::N3::Reader.open("lib/assets/graph.n3") do |reader|
  quads = reader.quads
  rules = quads.select{|quad| quad[1].fragment=='implies'}
  i=0
  rules.each do |k,p,v,g|
    step_type = StepType.create(:name => "Rule #{i}")
    i = i + 1
    conditions = quads.select{|quad| quad[3] === k}
    actions = quads.select{|quad| quad[3] === v}

    list_variables = []
    conditions.each do |k,p,v,g|
      unless list_variables.include?(k)
        condition_group = ConditionGroup.create(:step_type => step_type)
        list_variables.push(k)
      end
      Condition.create({ :predicate => p.fragment, :object => v.fragment,
        :condition_group_id => condition_group.id})
    end
  end
end


