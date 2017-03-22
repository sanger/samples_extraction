# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

reracking_activity_type = ActivityType.create(name: 'Re-Racking')
kit_type = KitType.create(name: 'Re-Racking', activity_type: reracking_activity_type)
kit = Kit.create(barcode: '9999', kit_type: kit_type)
instrument = Instrument.create(barcode: '9999', name: 'Re-Racking')

instrument.activity_types << reracking_activity_type
