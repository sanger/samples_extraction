class AddUuidToAssetGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :asset_groups, :uuid, :string, unique: true
  end
end
