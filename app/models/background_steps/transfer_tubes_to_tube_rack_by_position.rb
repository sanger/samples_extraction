class BackgroundSteps::TransferTubesToTubeRackByPosition < Step
  #
  #  {
  #    ?p :a :Tube .
  #    ?q :a :TubeRack .
  #    ?q :contains ?r .
  #    ?r :a :Tube .
  #   }
  #    =>
  #   {
  #    ?p :transfer ?r .
  #    :step :connectBy """position""" .
  #   } .
  #
  attr_accessor :printer_config

  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('transferToTubeRackByPosition').count > 0
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :step_type => StepType.find_or_create_by(:name => 'TransferTubesToTubeRackByPosition'),
      :asset_group => AssetGroup.create!(:assets => asset_group.assets.with_predicate('transferToTubeRackByPosition'))
    })
    background_job
  end

  def location_to_pos(location, max_row = 8)
    ((location[1..-1].to_i - 1) * max_row)+ (location[0].ord - 'A'.ord);
  end


  def background_job
    ActiveRecord::Base.transaction do 
      if assets_compatible_with_step_type
        rack = asset_group.assets.first.facts.with_predicate('transferToTubeRackByPosition').first.object_asset
        wells = rack.facts.with_predicate('contains').map(&:object_asset).sort_by do |elem|
          location = elem.facts.with_predicate('location').first.object
          location_to_pos(location)
        end
        asset_group.assets.with_predicate('transferToTubeRackByPosition').zip(wells).each do |asset, well|
          asset.add_facts([Fact.create(:predicate => 'transfer', :object_asset => well)])
          well.add_facts([Fact.create(:predicate => 'transferredFrom', :object_asset => asset)])
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