class AddConnectByToStepType < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction { |_t| add_column :step_types, :connect_by, :string }
  end
end
