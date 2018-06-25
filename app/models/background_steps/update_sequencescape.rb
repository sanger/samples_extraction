class BackgroundSteps::UpdateSequencescape < BackgroundSteps::BackgroundStep
  def assets_compatible_with_step_type
    asset_group.assets.with_fact('pushTo', 'Sequencescape').count > 0
  end

  def asset_group_for_execution
    AssetGroup.create!(:assets => asset_group.assets.with_fact('pushTo', 'Sequencescape'))
  end

  def process
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type
        asset_group.assets.each do |asset|
          asset.update_sequencescape(printer_config, user)
        end
      end
    end
  end

end
