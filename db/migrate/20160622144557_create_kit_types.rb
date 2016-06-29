class CreateKitTypes < ActiveRecord::Migration
  def change
    create_table :kit_types do |t|
      t.string :name
      t.string :target_type
      t.references :activity_type, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
