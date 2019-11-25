require 'importers/concerns/annotator'
require 'importers/concerns/changes'
require 'importers/concerns/remote_digest'

module Importers
  class BarcodesImporter
    attr_reader :barcodes

    include Importers::Concerns::Annotator
    include Importers::Concerns::Changes
    include Importers::Concerns::RemoteDigest

    def initialize(barcodes)
      @barcodes = barcodes
      @imported_uuids_by_barcode = {}
      @updates = FactChanges.new
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
      @updates.merge(refresh_assets(local_assets.from_remote_service))
      @updates.merge(import_barcodes(filter_barcodes_not_in_assets(barcodes, local_assets)))
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
