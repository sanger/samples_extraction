require 'csv'
require 'parsers/csv_layout'
module Parsers
  class CsvLayoutAnyBarcode < Parsers::CsvLayout
    def validate_tube_barcode_format(barcode)
    end
  end
end
