module PlateTransfer
  extend ActiveSupport::Concern

  def transfer_by_location(plate, destination)
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
      add_facts(asset2, asset1.facts.map(&:dup)) if asset2
    end
  end

  def transfer_with_asset_creation(plate, destination)
    contains_facts = plate.facts.with_predicate('contains').map do |contain_fact|
      well = contain_fact.object_asset.dup
      well.uuid = nil
      well.barcode = contain_fact.object_asset.barcode
      well.facts = contain_fact.object_asset.facts.map(&:dup)
      Fact.new(:predicate => 'contains', :object_asset => well)
    end
    add_facts(destination, contains_facts)
  end

  def transfer(plate, destination)
    if (destination.facts.with_predicate('contains').count > 0)
      transfer_by_location(plate, destination)
    else
      transfer_with_asset_creation(plate, destination)
    end
  end
end