class AddIndexToAssetBarcode < ActiveRecord::Migration
  def change
    add_index :assets, :barcode, unique: true
  end
end
