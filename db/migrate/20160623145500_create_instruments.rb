class CreateInstruments < ActiveRecord::Migration
  def change
    create_table :instruments do |t|
      t.string :barcode

      t.timestamps null: false
    end
  end
end
