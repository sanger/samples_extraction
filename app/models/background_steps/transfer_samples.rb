class BackgroundSteps::TransferSamples < BackgroundSteps::BackgroundStep
  include PlateTransfer
  def assets_compatible_with_step_type
    (asset_group.assets.with_predicate('transferredFrom').count > 0) ||
      (asset_group.assets.with_predicate('transfer').count > 0)
  end

  def asset_group_for_execution
    asset_group
  end

  def each_asset_and_modified_asset(&block)
    asset_group.assets.with_predicate('transfer').each do |asset|
      asset.facts.with_predicate('transfer').each do |fact|
        modified_asset = fact.object_asset
        yield(asset, modified_asset) if asset && modified_asset
      end
    end
    asset_group.assets.with_predicate('transferredFrom').each do |modified_asset|
      modified_asset.facts.with_predicate('transferredFrom').each do |fact|
        asset = fact.object_asset
        yield(asset, modified_asset) if asset && modified_asset
      end
    end    
  end

  def process
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type
        each_asset_and_modified_asset do |asset, modified_asset|
          added_facts = []
          added_facts.push([Fact.new(:predicate => 'is', :object => 'Used')])
          if (asset.has_predicate?('sample_tube'))
            added_facts.push([Fact.new(:predicate => 'sample_tube', 
              :object_asset => asset.facts.with_predicate('sample_tube').first.object_asset)])
          end
          if (asset.has_predicate?('study_name'))
            added_facts.push([Fact.new(:predicate => 'study_name', 
              :object => asset.facts.with_predicate('study_name').first.object)])
          end        
          added_facts.push(asset.facts.with_predicate('sanger_sample_id').map do |aliquot_fact|
            [
              Fact.new(:predicate => 'sanger_sample_id', :object => aliquot_fact.object),
              Fact.new(:predicate => 'sample_id', :object => aliquot_fact.object)
            ]
          end.flatten)
          unless modified_asset.has_predicate?('aliquotType')
            added_facts.concat(asset.facts.with_predicate('aliquotType').map do |aliquot_fact|
              [
                Fact.new(:predicate => 'aliquotType', :object => aliquot_fact.object)
              ]
            end.flatten)
          end
          added_facts.push(Fact.new(:predicate => 'transferredFrom', :object_asset => asset))
          added_facts = added_facts.flatten
          add_facts(modified_asset, added_facts)

          transfer(asset, modified_asset)
        end
      end
    end
  end

end