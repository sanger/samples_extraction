class BarcodeCreatableParser < BarcodeParser
  def updater
    @parser.parsed_changes
  end

  def asset
    asset = Asset.find_by_barcode(barcode)
    unless asset
      asset = Asset.new(barcode: barcode)
      asset.generate_uuid!
      updater.create_assets([asset])
      updater.add(asset, 'barcode', barcode)
      updater.add(asset , 'a', 'Tube')
      updater.create_asset_groups(["?created_tubes"])
    end
  end
end
