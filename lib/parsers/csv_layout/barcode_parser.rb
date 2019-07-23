require 'parsers/csv_layout/validators/any_barcode_validator'
require 'parsers/csv_layout/validators/fluidx_barcode_validator'

module Parsers
  module CsvLayout
    class BarcodeParser
      include ActiveModel::Validations

      validates :asset, presence: { message: "Cannot find the barcode" }
      validate :validations

      def validations
        validates_with @parser.components[:barcode_validator]
      end

      attr_reader :barcode, :asset

      def initialize(line, parser)
        @parser = parser
        @barcode = line[1].strip

        valid?
      end

      def no_read_barcode?
        barcode.downcase.start_with?('no read')
      end

      def asset
        Asset.find_by_barcode(barcode)
      end

    end
  end
end
