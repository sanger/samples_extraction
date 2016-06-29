class CreateCapacities < ActiveRecord::Migration
  def change
    create_table :capacities do |t|
      t.references :instrument, index: true, foreign_key: true
      t.references :activity_type, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
