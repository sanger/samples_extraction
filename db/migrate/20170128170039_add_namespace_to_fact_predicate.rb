class AddNamespaceToFactPredicate < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction { |_t| add_column :facts, :ns_predicate, :string }
  end
end
