class AddProcessAndStepRelatedTables < ActiveRecord::Migration
  def change
    create_table :steps do |t|
      t.integer :step_type_id
      t.date :completion_date
      t.integer :process_id
      t.timestamps
    end

    create_table :processes do |t|
      t.integer :process_type_id
      t.date :completion_date
      t.timestamps
    end
  end
end
