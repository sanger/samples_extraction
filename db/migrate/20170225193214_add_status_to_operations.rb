class AddStatusToOperations < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_column :operations, :cancelled?, :boolean, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
