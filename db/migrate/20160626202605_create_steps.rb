class CreateSteps < ActiveRecord::Migration
  def change
    create_table :steps do |t|
      t.references :step_type, index: true, foreign_key: true
      t.date :completion_date
      t.references :activity, index: true, foreign_key: true
      t.references :asset, index: true, foreign_key: true
      t.timestamps
    end
  end
end
