class AddPrinterConfigToStep < ActiveRecord::Migration
  def change
    add_column :steps, :printer_config, :text
  end
end
