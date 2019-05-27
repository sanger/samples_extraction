module Actions
  module PlateTransfer
    def transfer_by_location(plate, destination)
      FactChanges.new.tap do |updates|
        value = plate.facts.with_predicate('contains').reduce({}) do |memo, f|
          location = f.object_asset.facts.with_predicate('location').first.object
          memo[location] = [] unless memo[location]
          memo[location].push(f.object_asset)
          memo
        end
        value = destination.facts.with_predicate('contains').reduce(value) do |memo, f|
          location = f.object_asset.facts.with_predicate('location').first.object
          memo[location] = [] unless memo[location]
          memo[location].push(f.object_asset)
          memo
        end
        value.each do |location, assets|
          asset1, asset2 = assets
          if asset2
            asset1.facts.each do |fact|
              updates.add(asset2, fact.predicate, fact.object_value)
            end
          end
        end
      end
    end

    def transfer_with_asset_creation(plate, destination)
      FactChanges.new.tap do |updates|
        contains_facts = plate.facts.with_predicate('contains').map do |contain_fact|
          well = contain_fact.object_asset.dup
          well.uuid = nil
          well.barcode = contain_fact.object_asset.barcode
          well.facts = contain_fact.object_asset.facts.map(&:dup)
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
