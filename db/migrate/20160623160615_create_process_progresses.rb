class CreateProcessProgresses < ActiveRecord::Migration
  def change
    create_table :process_progresses do |t|
      t.references :capacity, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
