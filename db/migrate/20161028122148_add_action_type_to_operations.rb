class AddActionTypeToOperations < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction { |_t| add_column :operations, :action_type, :string }
  end
end
