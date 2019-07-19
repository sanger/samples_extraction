require 'csv'
require 'parsers/csv_layout'
module Parsers
  class CsvLayoutAnyBarcode < Parsers::CsvLayout
    def validate_barcode_format(barcode)
    end

    def valid_barcode?(barcode)
      true
    end
  end
end
