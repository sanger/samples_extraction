# frozen_string_literal: true

module StepPlanner
  # # This rule applies the barcodes from a rack into a plate
  # {
  #   ?plate se:a Plate .
  #   ?rack se:a TubeRack .
  #   ?rack se:mergeInto ?plate .
  #   ?rack se:contains ?tube .
  #   ?plate se:contains ?well .
  #   ?tube se:location ?location .
  #   ?tube se:barcode ?barcode .
  #   ?well se:location ?location .
  #   } => {
  #     :step :addFacts { ?well se:barcode ?barcode . } .
  #     :step :removeFacts { ?tube se:barcode ?barcode . } .
  #     :step :addFacts { ?tube se:barcode  . } .
  #     :step :addFacts { ?tube se:previousBarcode ?barcode . } .
  #     :step :addFacts { ?tube se:appliedBarcodeTo ?well . } .
  #     :step :addFacts { ?rack se:mergedInto ?plate .}.
  #     :step :addFacts { ?plate se:mergedFrom ?rack .}.
  #   }.
  class MoveBarcodesFromTubeRackToPlate
    attr_reader :asset_group

    def initialize(asset_group_id, _step_id)
      @asset_group = AssetGroup.find(asset_group_id)
    end

    def assets_compatible_with_step_type
      [plate, tube_rack].flatten.any?
    end

    def plate
      # TODO: Scope for improvement here, just adapted it sufficiently to make rubocop happy as I want to keep this
      # commit focussed on the move to using the same process
      asset_group.assets.detect { |a| a.facts.exists?(predicate: 'a', object: 'Plate') }
    end

    def tube_rack
      # TODO: Scope for improvement here, just adapted it sufficiently to make rubocop happy as I want to keep this
      # commit focussed on the move to using the same process
      asset_group.assets.detect { |a| a.facts.exists?(predicate: 'a', object: 'TubeRack') }
    end

    def wells_for(asset)
      asset.facts.where(predicate: 'contains').map(&:object_asset)
    end

    def well_at_location(asset, location)
      wells_for(asset).detect do |w|
        location_facts = w.facts.where(predicate: 'location')
        if location_facts.count == 1
          location_fact = location_facts.first
          (TokenUtil.pad_location(location_fact.object) == TokenUtil.pad_location(location))
        end
      end
    end

    def traverse_wells(asset)
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
            barcode = well_from_tube_rack.barcode
            updates.remove_where(well_from_tube_rack, 'barcode', barcode)
            updates.add(well_from_tube_rack, 'previousBarcode', barcode)
            updates.add(well_from_tube_rack, 'appliedBarcodeTo', well_from_plate)
            well_from_tube_rack.update(barcode: nil)
            well_from_plate.update(barcode: barcode)
            updates.add(well_from_plate, 'barcode', barcode)
          end

          updates.add(tube_rack, 'mergedInto', plate)
          updates.add(plate, 'mergedFrom', tube_rack)
        end
      end
    end

    def updates
      ActiveRecord::Base.transaction { process.to_h }
    rescue StandardError => e
      { set_errors: ["Unknown error while applying barcodes: #{e.message}, #{e.backtrace}"] }
    end
  end
end
