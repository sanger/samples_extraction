class AddProdConditionsAndFactsTables < ActiveRecord::Migration
  def change
    create_table :facts do |t|
      t.string :predicate, :null => false
      t.string :object, :null => true
      t.timestamps null: false
    end

    create_table :condition_groups do |t|
      t.references :step_type, index: true, foreign_key: true
      t.integer :cardinality, :null => true
    end

    create_table :conditions do |t|
      t.references :condition_group, index: true, foreign_key: true
      t.string :predicate, :null => false
      t.string :object, :null => true
      t.integer :subject_condition_id, :null => true
      t.integer :object_condition_id, :null => true
      t.timestamps :null => false
    end
  end
end
