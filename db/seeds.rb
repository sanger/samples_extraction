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

activity_type = ActivityType.create(:name => 'Testing activity type')

instrument = Instrument.create(:barcode => '1111')
instrument.activity_types << activity_type

kit_type = KitType.create(:activity_type => activity_type, :name => 'Testing kit type')
kit = Kit.create( {:kit_type => kit_type, :barcode => 1111})

activity_type2 = ActivityType.create(:name => 'Testing activity type 2')
kit_type = KitType.create(:activity_type => activity_type2, :name => 'Testing kit type 2')
kit = Kit.create( {:kit_type => kit_type, :barcode => 2222})

require 'support_n3'
SupportN3.load_n3("lib/assets/graph3.n3")
SupportN3.load_n3("lib/assets/graph2.n3")

