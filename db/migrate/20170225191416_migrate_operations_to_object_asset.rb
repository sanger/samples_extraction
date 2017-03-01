class MigrateOperationsToObjectAsset < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |t|
      Operation.where("object is not null").each do |oper|
        obj_asset = Asset.find_by(:uuid => oper.object)
        if obj_asset
          oper.update_attributes(:object_asset_id => obj_asset.id)
        end
      end
    end
  end
end
