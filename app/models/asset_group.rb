class AssetGroup < ActiveRecord::Base
  has_and_belongs_to_many :assets
  has_many :steps
  has_one :activity

  def select_barcodes(barcodes)
    barcodes.each do |barcode|
      if assets.select{|a| a.barcode == barcode}.empty?
        asset = Asset.find_by_barcode(barcode)
        return false if asset.nil?
        assets << asset
      end
    end
    return true
  end

  def unselect_barcodes(barcodes)
    barcodes.each do |barcode|
      selection = assets.select{|a| a.barcode == barcode}
      assets.delete(selection)
    end
  end

end
