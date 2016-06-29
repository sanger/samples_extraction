class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.references :activity_type, index: true, foreign_key: true
      t.references :instrument, index: true, foreign_key: true
      t.references :kit, index: true, foreign_key: true
      t.date :completion_date
      t.timestamps
    end
  end
end
