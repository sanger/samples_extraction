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
        updates.merge(rack_layout_creating_tubes)
      end
    end
  end
end

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts RackLayoutCreatingTubes.new(asset_group: asset_group).process.to_json

