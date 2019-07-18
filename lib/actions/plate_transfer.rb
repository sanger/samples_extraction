module Actions
  module PlateTransfer

    def to_sequencescape_location(location)
      loc = location.match(/(\w)(0*)(\d*)/)
      loc[1]+loc[3]
    end

    def ignored_predicates
      ['a', 'parent']
    end

    def validate_plate_is_compatible_with_aliquot(updates, plate, aliquotType)
      aliquots = plate.facts.with_predicate('aliquotType').map(&:object).uniq
      return true if aliquots.empty?
      if ((aliquots.size != 1) || (aliquots.first != aliquotType))
        updates.set_errors(
          ["The plate #{plate.barcode} contains aliquot #{aliquots.first} which is not compatible with #{aliquotType}"]
        )
        return false
      end
      true
    end


    def validate_tube_is_compatible_with_aliquot(updates, tube, aliquotType)
      aliquots = tube.facts.with_predicate('aliquotType').map(&:object).uniq
      return true if aliquots.empty?
      if ((aliquots.size != 1) || (aliquots.first != aliquotType))
        updates.set_errors(
          ["The tube #{tube.barcode} contains aliquot #{aliquots.first} which is not compatible with #{aliquotType}"]
        )
        return false
      end
      true
    end

    def transfer_by_location(plate, destination)
      aliquot = plate.facts.where(predicate: 'aliquotType').first
      FactChanges.new.tap do |updates|
        return updates unless validate_plate_is_compatible_with_aliquot(updates, destination, aliquot.object) if aliquot
        updates.add(destination, 'aliquotType', aliquot.object) if aliquot
        value = plate.facts.with_predicate('contains').reduce({}) do |memo, f|
          location = to_sequencescape_location(f.object_asset.facts.with_predicate('location').first.object)
          memo[location] = [] unless memo[location]
          memo[location].push(f.object_asset)
          memo
        end
        value = destination.facts.with_predicate('contains').reduce(value) do |memo, f|
          location = to_sequencescape_location(f.object_asset.facts.with_predicate('location').first.object)
          memo[location] = [] unless memo[location]
          memo[location].push(f.object_asset)
          memo
        end
        value.each do |location, assets|
          asset1, asset2 = assets
          if asset2
            return updates unless validate_tube_is_compatible_with_aliquot(updates, asset2, aliquot.object) if aliquot
            updates.add(asset2, 'aliquotType', aliquot.object) if aliquot && !asset2.has_predicate?('aliquotType')
            asset1.facts.each do |fact|
              unless ignored_predicates.include?(fact.predicate)
                updates.add(asset2, fact.predicate, fact.object_value)
              end
            end
          end
        end
      end
    end

    def transfer_with_asset_creation(plate, destination)
      aliquot = plate.facts.where(predicate: 'aliquotType').first
      FactChanges.new.tap do |updates|
        contains_facts = plate.facts.with_predicate('contains').map do |contain_fact|
          well = contain_fact.object_asset.dup
          well.uuid = nil
          well.barcode = contain_fact.object_asset.barcode
          well.facts = contain_fact.object_asset.facts.map(&:dup)
          updates.create_assets([well])
          contain_fact.object_asset.facts.each do |fact|
            updates.add(well, fact.predicate, fact.object_value)
          end
          updates.add(well, 'barcodeType', 'NoBarcode')
          updates.add(well, 'aliquotType', aliquot.object) if aliquot && !well.has_predicate?('aliquotType')
          updates.add(destination, 'contains', well)
        end
      end
    end

    def transfer_plates(plate, destination)
      FactChanges.new.tap do |updates|
        if (destination.facts.with_predicate('contains').count > 0)
          updates.merge(transfer_by_location(plate, destination))
        else
          updates.merge(transfer_with_asset_creation(plate, destination))
        end
      end
    end
  end
end
