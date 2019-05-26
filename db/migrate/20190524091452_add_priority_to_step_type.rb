class AddPriorityToStepType < ActiveRecord::Migration[5.1]
  def change
    add_column :step_types, :priority, :integer, default: 0, null: false
  end
end
