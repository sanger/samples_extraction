class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :login
      t.string :password
      t.string :barcode
      t.string :username
      t.string :fullname
      t.string :token

      t.timestamps null: false
    end
  end
end
