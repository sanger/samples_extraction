class AddNamespaceToFactPredicate < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |t|
      add_column :facts, :ns_predicate, :string
    end    
  end
end
