require 'parsers/csv_layout/barcode_parser'

module Parsers
  module CsvLayout
    class BarcodeCreatableParser < BarcodeParser
      def updater
        @parser.parsed_changes
      end

      def asset
        @instance ||= @parser.find_or_import_asset_with_barcode(barcode) # || Asset.create_local_asset(barcode, updater)

        return @instance if @instance

        # In reality I don't think we ever get here, as Asset.find_or_import_asset_with_barcode
        # will actually create assets for valid fluidx barcodes, and this is only used
        # in that context. However, this is definitely the more sensible way of handling this.

        @instance = Asset.new(barcode: barcode)
        updater.create_assets([@instance])
        updater.add(@instance, 'barcode', barcode)
        updater.add(@instance, 'a', 'Tube')
        @instance
      end
    end
  end
end
