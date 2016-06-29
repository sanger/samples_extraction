class CreateFacts < ActiveRecord::Migration
  def change
    create_table :facts do |t|
      t.string :predicate, :null => false
      t.string :object, :null => true
      t.timestamps null: false
    end
  end
end
