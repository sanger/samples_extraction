def print_list(user, printer_config, barcodes)
  ActiveRecord::Base.transaction do |t|
    assets = barcodes.map do |barcode|
      asset = Asset.create(barcode: barcode)
      asset.facts << Fact.create(predicate: 'a', object: 'Tube')
      asset.facts << Fact.create(predicate: 'barcodeType', object: 'Code128')
      asset
    end

    asset_group = AssetGroup.create
    asset_group.assets << assets
    asset_group.save
    asset_group.print(printer_config, user.username)
  end
end
