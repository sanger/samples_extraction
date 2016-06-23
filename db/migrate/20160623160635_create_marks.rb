class CreateMarks < ActiveRecord::Migration
  def change
    create_table :marks do |t|
      t.references :asset_group, index: true, foreign_key: true
      t.string :name
      t.date :complete?

      t.timestamps null: false
    end
  end
end
