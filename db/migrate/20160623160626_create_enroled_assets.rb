class CreateEnroledAssets < ActiveRecord::Migration
  def change
    create_table :enroled_assets do |t|
      t.references :asset_group, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
