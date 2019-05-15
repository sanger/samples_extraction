class PurposeNameInference
  attr_reader :asset_group
  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def _CODE
    %Q{
      {
        ?asset :contains ?anotherAsset .
        ?anotherAsset :aliquotType """DNA""" .
      }=>{
        :step :addFacts { ?asset :purpose """DNA Stock Plate""" } .
      } .

      {
        ?asset :contains ?anotherAsset .
        ?anotherAsset :aliquotType """RNA""" .
      }=>{
        :step :addFacts { ?asset :purpose """RNA Stock Plate""" } .
      } .

      @forAll :anotherAsset, :someAliquot .
      {
        ?asset :contains ?anotherAsset .
        ?anotherAsset log:notIncludes { :anotherAsset :aliquotType :someAliquot .} .
      } => {
        :step :addFacts { ?asset :purpose """Stock Plate""" } .
      }
    }
  end

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
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          updates.add(asset, 'purpose', purpose_for(asset))
        end
      end
    end
  end

end

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts PurposeNameInference.new(asset_group: asset_group).process.to_json

