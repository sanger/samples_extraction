class AddActionToStepType < ActiveRecord::Migration[5.1]
  def change
    add_column :step_types, :step_action, :string
  end
end
