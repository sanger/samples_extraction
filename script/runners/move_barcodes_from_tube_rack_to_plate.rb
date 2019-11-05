# # This rule applies the barcodes from a rack into a plate
# {
#   ?plate se:a """Plate""" .
#   ?rack se:a """TubeRack""" .
#   ?rack se:mergeInto ?plate .
#   ?rack se:contains ?tube .
#   ?plate se:contains ?well .
#   ?tube se:location ?location .
#   ?tube se:barcode ?barcode .
#   ?well se:location ?location .
#   } => {
#     :step :addFacts { ?well se:barcode ?barcode . } .
#     :step :removeFacts { ?tube se:barcode ?barcode . } .
#     :step :addFacts { ?tube se:barcode """""" . } .
#     :step :addFacts { ?tube se:previousBarcode ?barcode . } .
#     :step :addFacts { ?tube se:appliedBarcodeTo ?well . } .
#     :step :addFacts { ?rack se:mergedInto ?plate .}.
#     :step :addFacts { ?plate se:mergedFrom ?rack .}.
#   }.

class MoveBarcodesFromTubeRackToPlate
  attr_reader :asset_group


  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def assets_compatible_with_step_type
    [plate, tube_rack].flatten.compact.count > 0
  end


  def plate
    asset_group.assets.select{|a| a.facts.where(predicate: 'a', object: 'Plate').count > 0 }.first
  end

  def tube_rack
    asset_group.assets.select{|a| a.facts.where(predicate: 'a', object: 'TubeRack').count > 0}.first
  end

  def wells_for(asset)
    asset.facts.where(predicate: 'contains').map(&:object_asset)
  end

  def well_at_location(asset, location)
    wells_for(asset).select do |w|
      location_facts = w.facts.where(predicate: 'location')
      if (location_facts.count == 1)
        location_fact = location_facts.first
        (TokenUtil.pad_location(location_fact.object) ==  TokenUtil.pad_location(location))
      end
    end.first
  end

  def traverse_wells(asset, &block)
    wells_for(asset).each do |w|
      location = w.facts.where(predicate: 'location').first.object
      yield w, TokenUtil.pad_location(location)
    end
  end

  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type
        traverse_wells(tube_rack) do |well_from_tube_rack, location|
          well_from_plate = well_at_location(plate, location)
          updates.remove_where(well_from_tube_rack, 'barcode', well_from_tube_rack.barcode)
          updates.add(well_from_tube_rack, 'previousBarcode', well_from_tube_rack.barcode)
          updates.add(well_from_tube_rack, 'appliedBarcodeTo', well_from_plate)
          updates.add(well_from_plate, 'barcode', well_from_tube_rack.barcode)
        end

        updates.add(tube_rack, 'mergedInto', plate)
        updates.add(plate, 'mergedFrom', tube_rack)
      end
    end
  end
end

return unless ARGV.any?{|s| s.match(".json")}

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)

begin
  updates = MoveBarcodesFromTubeRackToPlate.new(asset_group: asset_group).process
  json = updates.to_json
  JSON.parse(json)
  puts json
rescue StandardError => e
  puts ({ set_errors: ['Unknown error while parsing file'+e.backtrace.to_s]}.to_json)
end


