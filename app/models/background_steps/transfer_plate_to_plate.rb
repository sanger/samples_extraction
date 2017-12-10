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
  attr_accessor :printer_config

  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate').count > 0
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :asset_group => AssetGroup.create!(:assets => asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate'))
    })
    background_job
  end


  def background_job
    ActiveRecord::Base.transaction do 
      aliquot_types = []
      if assets_compatible_with_step_type
        plates = asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate').each do |plate|
          plate.facts.with_predicate('transfer').each do |f|
            destination = f.object_asset
            transfer(plate, destination)
          end
        end
      end
    end
    update_attributes!(:state => 'complete')
    asset_group.touch
  ensure
    update_attributes!(:state => 'error') unless state == 'complete'
    asset_group.touch
  end

  handle_asynchronously :background_job

end