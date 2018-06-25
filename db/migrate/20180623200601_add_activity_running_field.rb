class AddActivityRunningField < ActiveRecord::Migration[5.1]
  def change
    add_column :activities, :running, :boolean
  end
end
