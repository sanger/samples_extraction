require 'actions/plate_transfer'

class TransferPlateToPlate
  include Actions::PlateTransfer

  attr_reader :asset_group
  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def _CODE

  end
  #
  #  {
  #    ?p :a :Plate .
  #    ?q :a :Plate .
  #    ?p :transfer ?q .
  #    ?p :contains ?tube .
  #   }
  #    =>
  #   {
  #    ?q :contains ?tube .
  #   } .
  #


  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate').count > 0
  end

  def asset_group_for_execution
    AssetGroup.create!(:assets => asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate'))
  end

  def process
    FactChanges.new.tap do |updates|
      aliquot_types = []
      if assets_compatible_with_step_type
        plates = asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate').each do |plate|
          plate.facts.with_predicate('transfer').each do |f|
            destination = f.object_asset
            updates.merge(transfer(plate, destination))
          end
        end
      end
    end
  end

end
return unless ARGV.any?{|s| s.match(".json")}

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts TransferPlateToPlate.new(asset_group: asset_group).process.to_json

