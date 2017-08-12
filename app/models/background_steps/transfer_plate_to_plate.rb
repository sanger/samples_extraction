class BackgroundSteps::TransferPlateToPlate < Step
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
  attr_accessor :printer_config

  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate').count > 0
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :step_type => StepType.find_or_create_by(:name => 'TransferPlateToPlate'),
      :asset_group => AssetGroup.create!(:assets => asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate'))
    })
    background_job
  end


  def transfer(plate, destination)
    value = plate.facts.with_predicate('contains').reduce({}) do |memo, f|
      location = f.object_asset.facts.with_predicate('location').first.object
      memo[location] = [] unless memo[location]
      memo[location].push(f.object_asset)
      memo
    end
    value = destination.facts.with_predicate('contains').reduce(value) do |memo, f|
      location = f.object_asset.facts.with_predicate('location').first.object
      memo[location] = [] unless memo[location]
      memo[location].push(f.object_asset)
      memo
    end
    value.each do |location, assets|
      asset1, asset2 = assets
      add_facts(asset2, asset1.facts.map(&:dup))
    end
  end

  def transfer_with_asset_creation(plate, destination)
    contains_facts = plate.facts.with_predicate('contains').map do |fact|
      # Create a new fact and asset with a new uuid
      fact = fact.dup
      fact.object_asset = fact.object_asset.dup
      fact.object_asset.uuid = nil
      fact
    end
    add_facts(destination, contain_facts)
  end

  def background_job
    ActiveRecord::Base.transaction do 
      aliquot_types = []
      if assets_compatible_with_step_type
        plates = asset_group.assets.with_predicate('transfer').with_fact('a', 'Plate').each do |plate|
          plate.facts.with_predicate('transfer').each do |f|
            destination = f.object_asset
            if (destination.facts.with_predicate('contains').count > 0)
              transfer(plate, destination)
            else
              transfer_with_asset_creation(plate, destination)
            end
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