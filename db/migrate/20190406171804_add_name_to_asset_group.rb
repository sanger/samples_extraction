class AddNameToAssetGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :asset_groups, :name, :string, default: nil, null: true
  end
end
