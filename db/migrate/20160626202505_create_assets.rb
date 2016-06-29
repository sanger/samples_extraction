class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.string :barcode, null: false
      t.timestamps null: false
    end
  end
end
