class BackgroundSteps::AliquotTypeInference < BackgroundSteps::BackgroundStep

  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('aliquotType').select { |a| a.has_predicate?('contains') }
  end

  def aliquot_type_fact(asset)
    asset.facts.with_predicate('aliquotType').first
  end

  def process
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          unless asset.facts.with_predicate('contains').map(&:object_asset).any? do |o| 
              o.has_predicate?('aliquotType')
            end
            asset.facts.with_predicate('contains').map(&:object_asset).each do |o|
              if o.has_predicate?('sample_tube')
                add_facts(o, [Fact.create(predicate: 'aliquotType', object: aliquot_type_fact(asset).object)])
              end
            end
          end
          remove_facts(asset, [aliquot_type_fact(asset)])
        end
      end
    end
  end
end
