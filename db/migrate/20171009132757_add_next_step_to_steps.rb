class AddNextStepToSteps < ActiveRecord::Migration
  def change
    add_column :steps, :next_step_id, :integer
    add_index :steps, :next_step_id
  end
end
