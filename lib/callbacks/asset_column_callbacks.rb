module Callbacks
  class AssetColumnCallbacks < Callback
    on_add_property('barcode', :update_asset_column!)
    on_add_property('uuid', :update_asset_column_unquoted!)
    on_add_property('remote_digest', :update_asset_column!)

    def self.update_asset_column!(tuple, updates, step)
      params = {}
      params[tuple[:predicate]] = tuple[:object]
      tuple[:asset].update_attributes(params)
    end

    def self.update_asset_column_unquoted!(tuple, updates, step)
      params = {}
      params[tuple[:predicate]] = TokenUtil.unquote(tuple[:object])
      tuple[:asset].update_attributes(params)
    end

  end
end
