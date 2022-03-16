class AddStateToStep < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |t|
      add_column :steps, :state, :string
    end
  end
end
