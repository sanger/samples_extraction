class RackLayout
  attr_reader :asset_group
  def initialize(params)
    @asset_group = params[:asset_group]
  end

  include Steps::Actions

  def assets_compatible_with_step_type
    asset_group.uploaded_files
  end


  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type.count > 0
        updates.merge(rack_layout)
      end
    end
  end
end

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts RackLayout.new(asset_group: asset_group).process.to_json

