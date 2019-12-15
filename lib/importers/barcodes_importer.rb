require 'importers/concerns/changes'

module Importers
  class BarcodesImporter
    include Importers::Concerns::Changes

    attr_reader :barcodes

    def initialize(barcodes)
      @barcodes = barcodes
      @updates = nil
      @imported_uuids_by_barcode = {}
      @annotators_by_uuid={}
    end

    def processed?
      !@updates.nil?
    end

    def changed_remote?(asset)
      annotator_for(asset).has_changes_between_local_and_remote?
      #process unless processed?
      #annotator_for(asset.uuid).has_changes_between_local_and_remote?
    end

    def annotator_for(asset)
      process unless processed?
      @annotators_by_uuid[asset.uuid]
    end

    def updates
      process unless processed?
      @updates
    end

    def imported_asset_for_barcode(barcode)
      updates.instances_from_uuid[@imported_uuids_by_barcode[barcode]]
    end

    def local_asset_for_barcode(barcode)
      local_assets.detect {|a| (a.barcode == barcode) || (a.uuid == barcode) }
    end

    def assets_for_barcodes
      barcodes.map do |barcode|
        local_asset_for_barcode(barcode) || imported_asset_for_barcode(barcode) || nil
      end
    end

    def process
      @updates = FactChanges.new
      @updates.merge(refresh_assets(local_assets.from_remote_service))
      @updates.merge(import_barcodes(filter_barcodes_not_in_assets(barcodes, local_assets.from_remote_service)))
    end

    def process!
      process.apply(step)
    end

    def local_assets
      Asset.where(barcode: barcodes).or(Asset.where(uuid: barcodes))
    end

    def step
      Step.new(step_type: StepType.find_or_create_by(name: 'BarcodesImporter'))
    end

    private

    def filter_barcodes_not_in_assets(barcodes, assets)
      (barcodes - (assets.map(&:barcode).concat(assets.map(&:uuid)).flatten))
    end

  end
end
