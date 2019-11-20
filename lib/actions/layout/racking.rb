require 'parsers/csv_layout/csv_parser'
require 'parsers/csv_layout/barcode_creatable_parser'
require 'parsers/csv_layout/validators/any_barcode_validator'
require 'fact_changes'

module Actions
  module Layout
    module Racking
      def reracking_tubes(rack, list_layout)
        FactChanges.new.tap do |updates|
          tubes = list_layout.map{|o| o[:asset]}.compact
          return updates unless tubes.length > 0
          updates.merge(changes_for_tubes_on_unrack(tubes))
          updates.merge(changes_for_racks_on_unrack(tubes))
          updates.merge(changes_for_rack_tubes(list_layout, rack))
        end
      end

      def changes_for_rack_when_racking_tubes(rack, racked_tubes)
        FactChanges.new.tap do |updates|
          Actions::LayoutProcessor::TUBE_TO_RACK_TRANSFERRABLE_PROPERTIES.map do |prop|
            racked_tubes.map{|tube| tube.facts.with_predicate(prop)}
          end.flatten.compact.each do |fact|
            updates.add(rack, fact.predicate.to_s, fact.object_value)
          end
        end
      end

      def changes_for_put_tube_into_rack_position(tube, rack, location)
        FactChanges.new.tap do |updates|
          updates.add(tube, 'location', location)
          updates.add(tube, 'parent', rack)
          updates.add(rack, 'contains', tube)
        end
      end

      def changes_for_rack_tubes(list_layout, rack)
        FactChanges.new.tap do |updates|
          tubes = []
          list_layout.each do |l|
            location = l[:location]
            tube = l[:asset]
            next unless tube
            tubes.push(tube)
            updates.merge(changes_for_put_tube_into_rack_position(tube, rack, location))
          end
          updates.merge(changes_for_rack_when_racking_tubes(rack, tubes))
        end
      end
    end
  end
end

