require 'actions/plate_transfer'

class TransferSamples
  include Actions::PlateTransfer

  attr_reader :asset_group
  def initialize(params)
    @asset_group = params[:asset_group]
  end

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
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type
        each_asset_and_modified_asset do |asset, modified_asset|
          updates.add(modified_asset, 'is', 'Used')
          if (asset.has_predicate?('sample_tube'))
            updates.add(modified_asset, 'sample_tube', asset.facts.with_predicate('sample_tube').first.object_asset)
          end
          if (asset.has_predicate?('study_name'))
            updates.add(modified_asset, 'study_name', asset.facts.with_predicate('study_name').first.object)
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
          updates.add(modified_asset, 'transferredFrom', asset)

          updates.merge(transfer(asset, modified_asset))
        end
      end
    end
  end

end

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts TransferSamples.new(asset_group: asset_group).process.to_json
