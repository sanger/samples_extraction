class UpdateSequencescape
  attr_reader :asset_group, :step
  def initialize(params)
    @asset_group = params[:asset_group]
    @step = params[:step]
  end

  def assets_compatible_with_step_type
    asset_group.assets.with_fact('pushTo', 'Sequencescape').count > 0
  end

  def asset_group_for_execution
    AssetGroup.create!(:assets => asset_group.assets.with_fact('pushTo', 'Sequencescape'))
  end

  def process
    FactChanges.new.tap do |updates|
      aliquot_types = []
      if assets_compatible_with_step_type
        ActiveRecord::Base.transaction do
          asset_group.assets.each do |asset|
            asset.update_sequencescape(step.printer_config, step.user, step)
          end
        end
      end
    end
  end

end

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
step_id = args.match(/(\d*)\.json/)[2]
step = Step.find(step_id)
puts UpdateSequencescape.new(asset_group: asset_group, step: step).process.to_json
