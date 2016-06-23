class CreateAssetGroups < ActiveRecord::Migration
  def change
    create_table :asset_groups do |t|
      t.references :step, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
