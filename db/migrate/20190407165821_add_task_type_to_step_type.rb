class AddTaskTypeToStepType < ActiveRecord::Migration[5.1]
  def change
    add_column :step_types, :task_type, :string, default: nil, null: true
  end
end
