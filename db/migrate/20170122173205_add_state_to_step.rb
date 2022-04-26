class AddStateToStep < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction { |_t| add_column :steps, :state, :string }
  end
end
