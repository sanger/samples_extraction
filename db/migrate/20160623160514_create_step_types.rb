class CreateStepTypes < ActiveRecord::Migration
  def change
    create_table :step_types do |t|
      t.string :name
      t.string :step_template, null: true
      t.integer :superceded_by_id, null: true, index: true
      t.timestamps null: false
    end
  end
end
