class CreateActions < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.string :action_type, :null => false
      t.references :condition_group, index: true, foreign_key: true
      t.references :step_type, index: true, foreign_key: true
      t.string :predicate, :null => false
      t.string :object, :null => true
      t.timestamps :null => false
    end
  end
end
