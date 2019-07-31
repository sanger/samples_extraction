require 'actions/racking'
include Actions::Racking

return unless ARGV.any?{|s| s.match(".json")}

updates = FactChanges.new

def location_for_position(i)
  letters = ("A".."H").to_a
  columns = (1..12).to_a
  "#{letters[(i%letters.length).floor]}#{(columns[i/letters.length]).to_s}"
end

args = ARGV[0]
out({}) unless args
matches = args.match(/(\d*)\.json/)
out({}) unless matches
asset_group_id = matches[1]
asset_group = AssetGroup.find(asset_group_id)
rack = asset_group.assets.joins(:facts).where(facts: { predicate: 'a', object: 'TubeRack'}).first
tube_ids_in_rack = rack.facts.with_predicate('contains').map(&:object_asset_id)
locations_with_tube = Fact.where(predicate: 'location', asset_id: tube_ids_in_rack).map(&:object)

tubes = asset_group.assets.joins(:facts).where(facts: { predicate: 'a', object: 'Tube'})

all_locations = 96.times.map{|i| location_for_position(i)}
available_locations = all_locations - locations_with_tube

if available_locations.length < tubes.length
  updates.set_error('There are not enough locations available for the tubes')
else
  layout = tubes.each_with_index.reduce([]) do |memo, list|
    tube = list[0]
    idx = list[1]
    location = available_locations[idx]
    memo.push(asset: tube, location: available_locations[idx])
  end
  updates.merge(Actions::Racking::reracking_tubes(rack, layout))
end

puts updates.to_json
