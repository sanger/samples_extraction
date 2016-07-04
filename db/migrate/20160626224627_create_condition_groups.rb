class CreateConditionGroups < ActiveRecord::Migration
  def change
    create_table :condition_groups do |t|
      t.references :step_type, index: true, foreign_key: true
      t.integer :cardinality, :null => true
    end
  end
end

