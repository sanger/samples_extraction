class BackgroundSteps::PrintBarcodes < BackgroundSteps::BackgroundStep

  def assets_compatible_with_step_type
    asset_group.assets.with_fact('is', 'readyForPrint').count > 0
  end

  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type
        asset_group.assets.each do |asset|
          asset.print(printer_config, user.username)
          # Do not print again unless the step fails
          updates.remove(Fact.where(asset: asset, predicate: 'is', object: 'readyForPrint'))
        end
      end
    end.apply(self)
  end

end
