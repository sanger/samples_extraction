class CreateConditionGroups < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :condition_groups do |t|
      t.string :name
      t.boolean :keep_selected, default: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.references :step_type, index: true, foreign_key: true
      t.integer :cardinality, null: true
    end
  end
end
