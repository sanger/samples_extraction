module Actions
  module Layout
    module Unracking

      def changes_for_tubes_on_unrack(tubes)
        FactChanges.new.tap do |updates|
          return unless tubes.length > 0
          contains_facts = Fact.where(predicate: 'contains', object_asset_id: tubes.map(&:id))
          parents_facts = Fact.where(asset_id: tubes.map(&:id), predicate: 'parent')
          locations_facts = Fact.where(asset_id: tubes.map(&:id), predicate: 'location')
          updates.remove(contains_facts)
          updates.remove(parents_facts)
          updates.remove(locations_facts)
          updates.merge(_metadata_changes_for_tubes_on_unrack(tubes, parents_facts, locations_facts))
        end
      end

      def changes_for_racks_on_unrack(tubes)
        FactChanges.new.tap do |updates|
          racks_for_tubes(tubes).each do |rack|
            updates.merge(changes_for_rack_on_unrack(rack, tubes))
          end
        end
      end

      def _metadata_changes_for_tubes_on_unrack(tubes, parents_facts, locations_facts)
        FactChanges.new.tap do |updates|
          tubes.each do |tube|
            parent_fact = parents_facts.detect{|f| f.asset_id == tube.id}
            location_fact = locations_facts.detect{|f| f.asset_id == tube.id}
            next unless parent_fact || location_fact
            rerack = Asset.new
            updates.create_assets([rerack])
            updates.add(rerack, 'a', 'Rerack')
            updates.add(rerack, 'barcodeType', 'NoBarcode')
            updates.add(rerack, 'previousParent', parent_fact.object_asset)
            updates.add(rerack, 'previousLocation', location_fact.object)
            updates.add(tube, 'rerack', rerack)
          end
        end
      end

      # For a plate modified (any plate that is losing a tube), it will resync the values of inherited
      # properties from the plates with the current list of tubes it contains
      def changes_for_rack_on_unrack(rack, tubes)
        FactChanges.new.tap do |updates|
          tubes_from_previous_rack = rack.facts.with_predicate('contains').map(&:object_asset)
          actual_tubes = (tubes_from_previous_rack - tubes)

          Actions::LayoutProcessor::TUBE_TO_RACK_TRANSFERRABLE_PROPERTIES.each do |transferrable_property|
            tubes.map{|tube| tube.facts.with_predicate(transferrable_property).map(&:object)}.flatten.compact.each do |value|
              updates.remove_where(rack, transferrable_property.to_s, value)
              #updates.merge(changes_for_remove_purpose(rack, value)) if transferrable_property.to_s == 'aliquotType'
            end
            actual_tubes.map{|tube| tube.facts.with_predicate(transferrable_property).map(&:object).flatten.compact}.each do |value|
              updates.add(rack, transferrable_property.to_s, value)
              #updates.merge(changes_for_add_purpose(rack, value)) if transferrable_property.to_s == 'aliquotType'
            end
          end
        end
      end
    end
  end
end
