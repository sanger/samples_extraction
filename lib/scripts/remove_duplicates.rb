module RemoveDuplicateWells 
  def object_from_asset(asset)
    asset.facts.with_predicate('contains').reduce({}) do |memo, fact|
      asset = fact.object_asset
      location = asset.facts.with_predicate('location').first.object
      memo[location] = [] unless memo[location]
      memo[location].push(asset)
      memo
    end    
  end

  def process_asset(asset)
    object_from_asset(asset).each do |location, assets|
      if assets.length == 2
        asset1, asset2 = assets
        asset1.add_facts(asset2.facts.map(&:dup))
        asset2.add_facts(asset1.facts.map(&:dup))
      end
    end
  end

  def unlink_contains(asset, well)
    asset.facts.with_predicate('contains').select do |f|
      f.object_asset.uuid == well.uuid
    end.each do |f|
      f.update_attributes(predicate: 'contains_old')
    end
  end

  # def unlink_contains(asset, well)
  #   asset.facts.with_predicate('contains').select do |f|
  #     f.object_asset == well
  #   end.each do |f|
  #     f.update_attributes(predicate: 'contains_old')
  #   end
  # end



  def remove_duplicates(asset)
    ActiveRecord::Base.transaction do
      uuids =SequencescapeClient.get_remote_asset(asset.barcode).wells.map(&:uuid)
      return unless uuids.length > 0
      object_from_asset(asset).each do |location, assets|
        if assets.length == 2
          asset1, asset2 = assets
          unless uuids.include?(asset1.uuid)
            unlink_contains(asset, asset1)
          end
          unless uuids.include?(asset2.uuid)
            unlink_contains(asset, asset2)
          end
          if asset1.uuid == asset2.uuid
            unless asset1.barcode
              unlink_contains(asset, asset1)
            end
            unless asset2.barcode
              unlink_contains(asset, asset2)
            end
          end
        end
      end
    end
  end

  def self.assets_with_wells_and_tubes(assets)
    assets.select do |asset|
      object_from_asset(asset).any? do |location, assets|
        assets.uniq.length == 2
      end
    end
  end

  def change
    self.assets_with_wells_and_tubes(Asset.with_fact('a', 'TubeRack')).each do |a| 
      remove_duplicates(a)
    end
  end
end
