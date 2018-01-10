class BackgroundSteps::StudyNameInference < BackgroundSteps::BackgroundStep
  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('contains').select do |a| 
      a.facts.with_predicate('contains').any? do |f|
        f.object_asset.has_predicate?('study_name')
      end
    end
  end

  def study_name_for(asset)
    list = asset.facts.with_predicate('contains').map do |f|
      f.object_asset.facts.with_predicate('study_name').map(&:object)
    end.flatten.compact.uniq
    return "" if list.count > 1
    return list.first
  end

  def process
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          add_facts(asset, [Fact.create(predicate: 'study_name', object: study_name_for(asset))])
        end
      end
    end
  end

end
