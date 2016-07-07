class CreateOperations < ActiveRecord::Migration[5.0]
  def change
    create_table :operations do |t|
      t.references :action, index: true, foreign_key: true
      t.references :step, index: true, foreign_key: true
      t.references :asset, index: true, foreign_key: true
      t.string :predicate
      t.string :object
      t.timestamps
    end
  end
end
