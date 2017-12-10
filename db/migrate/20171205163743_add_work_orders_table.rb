class AddWorkOrdersTable < ActiveRecord::Migration
  def change
    create_table :work_orders do |t|
      t.integer :work_order_id, index: true, unique: true
      t.references :activity, index: true, foreign_key: true, unique: true
      t.timestamps null: false
    end    
  end
end
