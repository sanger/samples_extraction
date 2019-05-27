require 'actions/racking'

class RackLayoutCreatingTubes
  attr_reader :asset_group

  include Actions::Racking

  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def assets_compatible_with_step_type
    asset_group.uploaded_files
  end


  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type.count > 0
        updates.merge(rack_layout_creating_tubes(@asset_group))
      end
    end
  end
end

return unless ARGV.any?{|s| s.match(".json")}

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)

begin
  updates = RackLayoutCreatingTubes.new(asset_group: asset_group).process
  json = updates.to_json
  JSON.parse(json)
  puts json
rescue InvalidDataParams => e
  puts ({ set_errors: e.errors }.to_json)
rescue StandardError
  puts ({ set_errors: ['Unknown error while parsing file']}.to_json)
end
