# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

asset=Asset.create!(:barcode => '1')
asset.facts << [
  ['is', 'Tube']
].map do |a,b|
  Fact.create({ :predicate => a, :object => b})
end

asset2=Asset.create!(:barcode => '2')
asset2.facts << [
  ['is', 'Tube']
].map do |a,b|
  Fact.create({ :predicate => a, :object => b})
end

asset2=Asset.create!(:barcode => '3')
asset2.facts << [
  ['is', 'Tube']
].map do |a,b|
  Fact.create({ :predicate => a, :object => b})
end

asset_group = AssetGroup.create
asset.asset_groups << asset_group

activity_type = ActivityType.create(:name => 'Testing activity type')
activity = Activity.create(:activity_type => activity_type)
activity_type.activities << activity

instrument = Instrument.create(:barcode => '1111')
instrument.activity_types << activity_type

kit_type = KitType.create(:activity_type => activity_type, :name => 'Testing kit type')
kit = Kit.create( {:kit_type => kit_type, :barcode => 1111})

#step_type = StepType.create(:name => 'Step B')
#step_type2 = StepType.create(:name => 'From Reception tube to Received tube')

#step_type.activity_types << activity_type
#step_type2.activity_types << activity_type

#condition_group = ConditionGroup.create(:step_type => step_type)

#conditions = [
#  ['is', 'ReceptionTube'],
#  ['aliquotType', 'DNA']
#].map do |a,b|
#  Condition.create({
#    :predicate => a, :object => b, :condition_group_id => condition_group.id})
#end

#step = Step.create({
#  :step_type_id => step_type2.id,
#  :activity_id => activity.id,
#})

#asset_group.steps << step

require 'support_n3'
SupportN3.load_n3("lib/assets/graph3.n3")

