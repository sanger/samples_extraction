class AddStiToStep < ActiveRecord::Migration
  def change
  	add_column :steps, :sti_type, :string
  end
end
