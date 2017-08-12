class AddOutputToSteps < ActiveRecord::Migration
  def change
    add_column :steps, :output, :longtext
  end
end
