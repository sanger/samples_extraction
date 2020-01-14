#
# Initialization of actions to perform when some properties are added or removed.
#
# TODO:
# This is not in an initializer because these configuration changes need to be available to
# every actual and future runner, but runners do not load Rails initializers by default,
# In order to have this config as an initializer we would need to modify Rails loading.
module FactChangesInitializers
  def self.included(klass)
    klass.instance_eval do
      FactChangesInitializers.setup_changes_callbacks!
    end
  end

  def self.setup_changes_callbacks!
    Callbacks.initialize_barcode_callbacks
    Callbacks.initialize_aliquot_type_callbacks
    Callbacks.initialize_digest_update_callbacks
  end

  module Callbacks
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

    def self.initialize_barcode_callbacks
      FactChanges.on_change_predicate('add_facts', 'barcode', Proc.new do |t|
        t[:asset].update_attributes(barcode: t[:object])
      end)

      FactChanges.on_change_predicate('remove_facts', 'barcode', Proc.new do |t, updates, step|
        t[:asset].update_attributes(barcode: nil)

        if(t[:asset].facts.with_predicate('barcode').length == 0)
          Operation.create(action_type: 'removeFacts', step: step, asset: t[:asset],
            predicate: 'barcode', object: t[:object], object_asset: nil)
        end
      end)
    end

    def self.initialize_digest_update_callbacks
      FactChanges.on_change_predicate('add_facts', 'remote_digest', Proc.new do |t, updates|
        t[:asset].update_attributes(remote_digest: t[:object])
      end)
    end

    def self.initialize_aliquot_type_callbacks
      FactChanges.on_change_predicate('add_facts', 'aliquotType', Proc.new do |t, updates|
        if t[:asset].kind_of_plate?
          updates.add(t[:asset], 'purpose', purpose_for_aliquot(t[:object]))
        end
      end)
      FactChanges.on_change_predicate('remove_facts', 'aliquotType', Proc.new do |t, updates|
        if t[:asset].kind_of_plate?
          updates.remove_where(t[:asset], 'purpose', purpose_for_aliquot(t[:object]))
        end
      end)
    end
  end
end
