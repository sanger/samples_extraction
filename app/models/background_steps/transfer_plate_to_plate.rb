class BackgroundSteps::TransferPlateToPlate < BackgroundSteps::BackgroundStep
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
  include PlateTransfer

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
    end.apply(self)
  end

end