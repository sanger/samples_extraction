module Assets::Import

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  class RefreshSourceNotFoundAnymore < StandardError ; end

  module InstanceMethods
    include Assets::Import::RemoteDigest

    def refresh
      updates = self.class.changes_for_refresh_asset(self, forceRefresh: false)
      updates.apply(self.class.create_refresh_step)
    end

    def refresh!
      updates = self.class.changes_for_refresh_asset(self, forceRefresh: true)
      updates.apply(self.class.create_refresh_step)
    end

    def assets_to_refresh
      # We need to destroy also the remote facts of the contained wells on refresh
      [self, facts.with_predicate('contains').map(&:object_asset).select do |asset|
        asset.facts.from_remote_asset.count > 0
      end].flatten
    end

    def is_refreshing_right_now?
      Step.running_with_asset(self).count > 0
    end

    def is_remote_asset?
      facts.from_remote_asset.count > 0
    end

  end

  module ClassMethods

    include Assets::Import::Annotator
    include Assets::Import::Changes

    def find_or_import_assets_with_barcodes(barcodes)
      updates = changes_for_refresh_or_import_assets_with_barcodes(barcodes)
      updates.apply(create_refresh_step)
      _find_assets_with_barcodes(barcodes)
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
