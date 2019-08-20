require 'parsers/csv_layout/validators/any_barcode_validator'
require 'parsers/csv_layout/validators/fluidx_barcode_validator'

module Parsers
  module CsvLayout
    class BarcodeParser

      NO_READ_BARCODE = 'no read'

      include ActiveModel::Validations

      validates :asset, presence: { message: "Cannot find the barcode" }
      validate :validations

      def validations
        validates_with @parser.components[:barcode_validator]
      end

      attr_reader :barcode, :asset

      def initialize(line, parser)
        @parser = parser
        _parse(line)

        valid?
      end

      def no_read_barcode?
        !barcode.nil? && barcode.downcase.start_with?(NO_READ_BARCODE)
      end

      def asset
        Asset.find_by_barcode(barcode)
      end

      protected
      def _parse(line)
        begin
          @barcode = line[1].strip
        rescue StandardError => e
          errors.add(:barcode, 'There was an error while parsing the barcode')
        end
      end
    end
  end
end
