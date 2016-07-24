class AssetToFactsCounterCache < ActiveRecord::Migration[5.0]
  def change
    add_column :assets, :facts_count, :integer
  end
end
