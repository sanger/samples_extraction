module Assets::Import

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  class RefreshSourceNotFoundAnymore < StandardError ; end

  module InstanceMethods

    def refresh
      Importers::BarcodesImporter.new([self.uuid]).refresh
    end

    def refresh!
      Importers::BarcodesImporter.new([self.uuid]).refresh!
    end

    def assets_to_refresh
      # We need to destroy also the remote facts of the contained wells on refresh
      [self, facts.with_predicate('contains').map(&:object_asset).select do |asset|
        asset.facts.from_remote_asset.count > 0
      end].flatten
    end

    def is_remote_asset?
      !remote_digest.nil?
    end

    def changed_remote?
      Importers::BarcodesImporter.new([self.uuid]).changed_remote?(self)
    end

    def digest_for_remote(remote)
      Importers::BarcodesImporter.new([self.uuid]).digest_for_remote_asset(remote)
    end

  end

  module ClassMethods

    def find_or_import_assets_with_barcodes(barcodes)
      importer = Importers::BarcodesImporter.new(barcodes)
      importer.process!
      importer.assets_for_barcodes
    end

    def changes_for_refresh_or_import_assets_with_barcodes(barcodes)
      FactChanges.new.tap do |updates|
        updates.merge(changes_for_refresh_from_barcodes(barcodes))
        updates.merge(changes_for_import_new_barcodes(barcodes))
      end
    end

    def create_refresh_step
      Step.create(step_type: StepType.find_or_create_by(name: 'Refresh'), state: 'running')
    end

    def find_or_import_asset_with_barcode(barcode)
      find_or_import_assets_with_barcodes([barcode]).first
    end

    def _find_assets_with_barcodes(barcodes)
      Asset.where(barcode: barcodes).or(Asset.where(uuid: barcodes))
    end

  end
end
