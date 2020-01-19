module Callbacks
  class BarcodeCallbacks < Callback
    on_add_property('barcode', :update_barcode!)
    on_remove_property('barcode', :clear_barcode!)

    def self.update_barcode!(tuple, updates, step)
      tuple[:asset].update_attributes(barcode: tuple[:object])
    end

    def self.clear_barcode!(tuple, updates, step)
      tuple[:asset].update_attributes(barcode: nil)

      if(tuple[:asset].facts.with_predicate('barcode').length == 0)
        Operation.create(action_type: 'removeFacts', step: step, asset: tuple[:asset],
          predicate: 'barcode', object: tuple[:object], object_asset: nil)
      end
    end
  end
end
