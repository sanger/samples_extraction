class AliquotTypeInference
  attr_reader :asset_group

  def initialize(params)
    @asset_group = params[:asset_group]
  end
  # rubocop:todo Naming/MethodName
  def _CODE
    %Q{
      {
        ?asset :aliquotType ?aliquot .
        ?asset :contains ?anotherAsset .
        ?anotherAsset :sample_tube ?tube .
      } => {
        :step :addFacts { ?anotherAsset :aliquotType ?aliquot . }
      }
    }
  end
  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('aliquotType').select { |a| a.has_predicate?('contains') }
  end

  def aliquot_type_fact(asset)
    asset.facts.with_predicate('aliquotType').first
  end

  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          unless asset.facts.with_predicate('contains').map(&:object_asset).any? do |o|
              o.has_predicate?('aliquotType')
            end
            asset.facts.with_predicate('contains').map(&:object_asset).each do |o|
              if o.has_predicate?('sample_tube')
                updates.add(o, 'aliquotType', aliquot_type_fact(asset).object)
              end
            end
          end
          updates.remove(aliquot_type_fact(asset))
        end
      end
    end
  end
end

def out(val)
  puts val.to_json
  return
end

return unless ARGV.any? { |s| s.match(".json") }
args = ARGV[0]
out({}) unless args

matches = args.match(/(\d*)\.json/)
out({}) unless matches
asset_group_id = matches[1]
asset_group = AssetGroup.find(asset_group_id)

out(AliquotTypeInference.new(asset_group: asset_group).process)
# rubocop:enable Naming/MethodName
