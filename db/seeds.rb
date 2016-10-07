# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'support_n3'
SupportN3.parse_file("lib/assets/graph.n3")
SupportN3.parse_file("lib/assets/graph3.n3")
SupportN3.parse_file("lib/assets/graph2.n3")
SupportN3.parse_file("lib/assets/reracking.n3")
SupportN3.parse_file("lib/workflows/biorobot_investigator.n3")
SupportN3.parse_file("lib/workflows/qiacube_ht.n3")
SupportN3.parse_file("lib/workflows/qiasymphony.n3")


TEST_SAMPLES = ['4086STDY6316833', '4086STDY6316834', '4086STDY6316835','4086STDY6316836','4086STDY6316837']


def test_sample_id(i)
  TEST_SAMPLES[i % TEST_SAMPLES.length]
end

tube_printer = Printer.create!(:name => 'e367bc', :printer_type => 'Tube', :default_printer => true)
plate_printer = Printer.create!(:name => 'ippbc', :printer_type => 'Plate', :default_printer => false)
tube_printer = Printer.create!(:name => 'e368bc', :printer_type => 'Tube', :default_printer => false)
plate_printer = Printer.create!(:name => 'd304bc', :printer_type => 'Plate', :default_printer => true)
plate_printer = Printer.create!(:name => 'd305bc', :printer_type => 'Plate', :default_printer => false)
plate_printer = Printer.create!(:name => 'f225bc', :printer_type => 'Plate', :default_printer => false)


asset=Asset.create!(:barcode => '1')
asset.facts << [
  ['a', 'SampleTube'],
  ['aliquotType', 'RNA']
].map do |a,b|
  Fact.create({ :predicate => a, :object => b})
end

asset2=Asset.create!(:barcode => '2')
asset2.facts << [
  ['a', 'SampleTube'],
  ['aliquotType', 'DNAP']
].map do |a,b|
  Fact.create({ :predicate => a, :object => b})
end

asset2=Asset.create!(:barcode => '3')
asset2.facts << [
  ['a', 'SampleTube'],
  ['aliquotType', 'Blood']
].map do |a,b|
  Fact.create({ :predicate => a, :object => b})
end



activity_type = ActivityType.find_by_name('Testing activity type')


instrument = Instrument.create(:barcode => '1111', :name => 'An instrument')
instrument.activity_types << activity_type

kit_type = KitType.create(:activity_type => activity_type, :name => 'Testing kit type')
kit = Kit.create( {:kit_type => kit_type, :barcode => 1111})

activity_type2 = ActivityType.find_by_name('Testing activity type 2')
kit_type = KitType.create(:activity_type => activity_type2, :name => 'Testing kit type 2')
kit = Kit.create( {:kit_type => kit_type, :barcode => 2222})


asset_group = AssetGroup.create!

100.times do |pos|
  asset = Asset.create!
  asset.generate_barcode
  asset.facts << Fact.create({ :predicate => 'a', :object => 'SampleTube'})
  asset.facts << Fact.create({ :predicate => 'is', :object => 'NotStarted'})
  asset.facts << Fact.create({ :predicate => 'aliquotType', :object => 'DNA'})
  asset_group.assets << asset
  asset.update_compatible_activity_type
end

activity_type.activities.create!(:asset_group => asset_group, :kit => kit, :instrument => instrument)

User.create!(:barcode => 1, :username => 'test', :fullname => 'Testing user')
User.create!(:barcode => 2, :username => 'admin', :fullname => 'Admin', :role => 'administrator')


activity_type = ActivityType.find_by_name('QIASymphony')
instrument.activity_types << activity_type
kit_type = KitType.create(:activity_type => activity_type, :name => 'QIASymphony')
kit = Kit.create( {:kit_type => kit_type, :barcode => 7777})

50.times do |pos|
  asset = Asset.create!(:barcode => 700 + pos)
  asset.facts << Fact.create({ :predicate => 'a', :object => 'SampleTube'})
  asset.facts << Fact.create({ :predicate => 'is', :object => 'NotStarted'})
  asset.facts << Fact.create({ :predicate => 'aliquotType', :object => 'DNA'})

  asset.facts << Fact.create({ :predicate => 'sanger_sample_id', :object => test_sample_id(pos)})

  asset_group.assets << asset
  asset.update_compatible_activity_type
end


activity_type = ActivityType.find_by_name('QIAamp Investigator BioRobot')
instrument.activity_types << activity_type
kit_type = KitType.create(:activity_type => activity_type, :name => 'QIAamp Investigator BioRobot')
kit = Kit.create( {:kit_type => kit_type, :barcode => 8888})

50.times do |pos|
  asset = Asset.create!(:barcode => 800 + pos)
  asset.facts << Fact.create({ :predicate => 'a', :object => 'Plate'})
  asset.facts << Fact.create({ :predicate => 'a', :object => 'LysedPlate'})
  asset.facts << Fact.create({ :predicate => 'is', :object => 'NotStarted'})
  asset.update_compatible_activity_type
end

50.times do |pos|
  asset = Asset.create!(:barcode => 850 + pos)
  asset.facts << Fact.create({ :predicate => 'a', :object => 'SampleTube'})
  asset.facts << Fact.create({ :predicate => 'is', :object => 'NotStarted'})

  asset.facts << Fact.create({ :predicate => 'sanger_sample_id', :object => test_sample_id(pos)})
  asset.update_compatible_activity_type
end

activity_type = ActivityType.find_by_name('QIAamp 96 DNA QIAcube HT')
instrument.activity_types << activity_type
kit_type = KitType.create(:activity_type => activity_type, :name => 'QIAamp 96 DNA QIAcube HT')
kit = Kit.create( {:kit_type => kit_type, :barcode => 9999})

50.times do |pos|
  asset = Asset.create!(:barcode => 900 + pos)
  asset.facts << Fact.create({ :predicate => 'a', :object => 'Plate'})
  asset.facts << Fact.create({ :predicate => 'is', :object => 'NotStarted'})
  asset.update_compatible_activity_type
end

