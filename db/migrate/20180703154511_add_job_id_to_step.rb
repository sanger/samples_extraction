class AddJobIdToStep < ActiveRecord::Migration[5.1]
  def change
    add_column :steps, :job_id, :integer
  end
end
