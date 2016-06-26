class AddProdConditionsAndFactsTables < ActiveRecord::Migration
  def change
    create_table :prod_facts do |t|
      t.string :predicate, :null => false
      t.string :object, :null => true
    end

    create_table :prod_condition_groups do |t|
      t.integer :step_type_id, :null => false
      t.integer :cardinality, :null => true      
    end

    create_table :prod_conditions do |t|
      t.integer :prod_condition_group_id, :null => false
      t.string :predicate, :null => false
      t.string :object, :null => true
      t.integer :subject_condition_id, :null => true
      t.integer :object_condition_id, :null => true
      t.timestamps :null => false
    end    
  end
end
