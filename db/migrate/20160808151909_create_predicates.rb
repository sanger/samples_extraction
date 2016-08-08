class CreatePredicates < ActiveRecord::Migration[5.0]
  def change
    create_table :predicates do |t|
      t.string :name
      t.timestamps
    end
  end
end
