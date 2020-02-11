class RemoveBarcodesFromTubes
  attr_reader :asset_group


  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def asset
    plate || tube_rack
  end

  def plate
    asset_group.assets.select{|a| a.facts.where(predicate: 'a', object: 'Plate').count > 0 }.first
  end

  def tube_rack
    asset_group.assets.select{|a| a.facts.where(predicate: 'a', object: 'TubeRack').count > 0}.first
  end

  def tubes
    asset.facts.with_predicate('contains').map(&:object_asset)
  end

  def assets_compatible_with_step_type
    !asset.nil?
  end


  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type
        tubes.each do |tube|
          updates.remove_where(tube, 'barcode', tube.barcode) if tube.barcode
        end
      end
    end
  end

end

return unless ARGV.any?{|s| s.match(".json")}

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)

begin
  updates = RemoveBarcodesFromTubes.new(asset_group: asset_group).process
  json = updates.to_json
  JSON.parse(json)
  puts json
rescue StandardError => e
  puts ({ set_errors: ['Unknown error while parsing file'+e.backtrace.to_s]}.to_json)
end
