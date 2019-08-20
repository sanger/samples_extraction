require 'parsers/csv_layout/barcode_parser'

module Parsers
  module CsvLayout
    class BarcodeCreatableParser < BarcodeParser
      def updater
        @parser.parsed_changes
      end

      def asset
        @instance ||= Asset.find_or_import_asset_with_barcode(barcode)
        unless @instance
          @instance = Asset.new(barcode: barcode)
          @instance.generate_uuid!
          updater.create_assets([@instance])
          updater.add(@instance, 'barcode', barcode)
          updater.add(@instance , 'a', 'Tube')
        end
        @instance
      end
    end
  end
end
