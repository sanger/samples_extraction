class ChangeExtrAttrToLongText < ActiveRecord::Migration
  def change
    change_column :delayed_jobs, :last_error, :text, limit: 4_294_967_295
  end
end
