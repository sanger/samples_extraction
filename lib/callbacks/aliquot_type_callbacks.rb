module Callbacks
  class AliquotTypeCallbacks < Callback
    on_add_property('aliquotType', :add_purpose_if_is_a_plate!)
    on_remove_property('aliquotType', :remove_purpose_if_is_a_plate!)

    DNA_STOCK_PLATE_PURPOSE = 'DNA Stock Plate'
    RNA_STOCK_PLATE_PURPOSE = 'RNA Stock Plate'
    STOCK_PLATE_PURPOSE = 'Stock Plate'
    DNA_ALIQUOT = 'DNA'
    RNA_ALIQUOT = 'RNA'

    def self.purpose_for_aliquot(aliquot)
      if aliquot == DNA_ALIQUOT
        DNA_STOCK_PLATE_PURPOSE
      elsif aliquot == RNA_ALIQUOT
        RNA_STOCK_PLATE_PURPOSE
      else
        STOCK_PLATE_PURPOSE
      end
    end

    def self.add_purpose_if_is_a_plate!(tuple, updates, step)
      if tuple[:asset].kind_of_plate?
        updates.add(tuple[:asset], 'purpose', purpose_for_aliquot(tuple[:object]))
      end
    end

    def self.remove_purpose_if_is_a_plate!(tuple, updates, step)
      if tuple[:asset].kind_of_plate?
        updates.remove_where(tuple[:asset], 'purpose', purpose_for_aliquot(tuple[:object]))
      end
    end

  end
end
