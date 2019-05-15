class TransferTubesToTubeRackByPosition
  attr_reader :asset_group
  def initialize(params)
    @asset_group = params[:asset_group]
  end

  #
  #  {
  #    ?p :a :Tube .
  #    ?q :a :TubeRack .
  #    ?q :contains ?r .
  #    ?r :a :Tube .
  #   }
  #    =>
  #   {
  #    ?p :transfer ?r .
  #    :step :connectBy """position""" .
  #   } .
  #

  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('transferToTubeRackByPosition').count > 0
  end

  def asset_group_for_execution
    AssetGroup.create!(:assets => asset_group.assets.with_predicate('transferToTubeRackByPosition'))
  end

  def location_to_pos(location, max_row = 8)
    ((location[1..-1].to_i - 1) * max_row)+ (location[0].ord - 'A'.ord);
  end

  def process
    FactChanges.new.tap do |updates|
      aliquot_types = []
      if assets_compatible_with_step_type
        rack = asset_group.assets.first.facts.with_predicate('transferToTubeRackByPosition').first.object_asset
        wells = rack.facts.with_predicate('contains').map(&:object_asset).sort_by do |elem|
          location = elem.facts.with_predicate('location').first.object
          location_to_pos(location)
        end.reject{|w| w.has_predicate?('transferredFrom')}.uniq
        asset_group.assets.with_predicate('transferToTubeRackByPosition').zip(wells).each do |asset, well|
          if asset && well
            asset.facts.with_predicate('aliquotType').each do |f_aliquot|
              aliquot_types.push(f_aliquot.object)
            end

            updates.add(asset, 'transfer', well)
            updates.add(well, 'transferredFrom', asset)
            updates.remove(asset.facts.with_predicate('transferToTubeRackByPosition'))
          end
        end
        if aliquot_types
          if (((aliquot_types.uniq.length) == 1) && (aliquot_types.uniq.first == 'DNA'))
            purpose_name = 'DNA Stock Plate'
          elsif (((aliquot_types.uniq.length) == 1) && (aliquot_types.uniq.first == 'RNA'))
            purpose_name = 'RNA Stock Plate'
          else
            purpose_name = 'Stock Plate'
          end
          updates.add(rack, 'purpose', purpose_name)
        end
      end
    end
  end

end

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts TransferTubesToTubeRackByPosition.new(asset_group: asset_group).process.to_json
