class BackgroundSteps::StudyNameInference < Activities::BackgroundTasks::BackgroundStep
  def _CODE
    %Q{
      {
        ?asset :contains ?anotherAsset .
        ?anotherAsset :study_name ?study .
      }=>{
        :step :addFacts { ?asset :study_name ?study . } .
      }.
    }
  end

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
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          updates.add(asset, 'study_name', study_name_for(asset))
        end
      end
    end.apply(self)
  end

end
