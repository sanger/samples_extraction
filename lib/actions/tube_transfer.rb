module Actions
  module TubeTransfer
    def transfer_tubes(asset, modified_asset)
      FactChanges.new.tap do |updates|
        if (asset.has_predicate?('sample_tube'))
          updates.add(modified_asset, 'sample_tube',
            asset.facts.with_predicate('sample_tube').first.object_asset)
        end
        if (asset.has_predicate?('study_name'))
          updates.add(modified_asset, 'study_name',
            asset.facts.with_predicate('study_name').first.object)
        end

        asset.facts.with_predicate('sanger_sample_id').each do |aliquot_fact|
          updates.add(modified_asset, 'sanger_sample_id', aliquot_fact.object)
          updates.add(modified_asset, 'sample_id', aliquot_fact.object)
        end
        unless modified_asset.has_predicate?('aliquotType')
          asset.facts.with_predicate('aliquotType').each do |aliquot_fact|
            updates.add(modified_asset, 'aliquotType', aliquot_fact.object)
          end
        end
      end
    end
  end
end
