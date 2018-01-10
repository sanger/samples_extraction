class BackgroundSteps::PurposeNameInference < BackgroundSteps::BackgroundStep
  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('contains').select do |a| 
      a.facts.with_predicate('contains').any? do |f|
        f.object_asset.has_predicate?('aliquotType')
      end
    end
  end

  def purpose_for_aliquot(aliquot)
    return 'DNA Stock Plate' if aliquot == 'DNA'
    return 'RNA Stock Plate' if aliquot == 'RNA'
    return 'Stock Plate'
  end

  def purpose_for(asset)
    list = asset.facts.with_predicate('contains').map do |f|
      f.object_asset.facts.with_predicate('aliquotType').map(&:object)
    end.flatten.compact.uniq
    return "" if list.count > 1
    return purpose_for_aliquot(list.first)
  end

  def process
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          add_facts(asset, [Fact.create(predicate: 'purpose', object: purpose_for(asset))])
        end
      end
    end
  end

end
