class RemoveBarcodesFromTubesQuickSolution
  attr_reader :asset_group, :activity_id


  def initialize(params)
    @asset_group = params[:asset_group]
    @activity_id = params[:activity_id]
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

  def step
    @step ||= Step.create(
        step_type: StepType.find_or_create_by(name: 'RemoveBarcodes - Management Fix'),
        activity_id: activity_id,
        asset_group: asset_group,
        state: 'complete'
    )
  end

  def process
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type
        tubes.each do |tube|
          if tube.barcode
            Operation.create!(action_type: 'removeFacts', step: step, asset: tube,
              predicate: 'barcode', object: tube.barcode, object_asset: nil)
            tube.update_attributes(barcode: nil)
          end
        end
      end
    end
  end
end

return unless ARGV.any?{|s| s.match(".json")}

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
activity_id = ARGV[1]
asset_group = AssetGroup.find(asset_group_id, activity_id)

begin
  updates = RemoveBarcodesFromTubesQuickSolution.new(asset_group: asset_group, activity_id: activity_id).process
  json = updates.to_json
  JSON.parse(json)
  puts json
rescue StandardError => e
  puts ({ set_errors: ['Unknown error while parsing file'+e.backtrace.to_s]}.to_json)
end

