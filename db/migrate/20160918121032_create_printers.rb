class CreatePrinters < ActiveRecord::Migration
  def change
    create_table :printers do |t|
      t.string :name, null: false, unique: true
      t.string :printer_type, null: false, unique: true
      t.boolean :default_printer, null: false, unique: true
      t.timestamps null: false
    end
  end
end
