class BackgroundSteps::PrintBarcodes < BackgroundSteps::BackgroundStep

  def assets_compatible_with_step_type
    asset_group.assets.with_fact('is', 'readyForPrint').count > 0
  end

  def process
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type
        asset_group.assets.each do |asset|
          asset.print(printer_config, user.username)
          # Do not print again unless the step fails
          remove_facts(asset, Fact.new(predicate: 'is', object: 'readyForPrint'))
        end
      end
    end
  end

end
