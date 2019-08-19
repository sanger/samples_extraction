module Parsers
  module CsvMetadata
    class DatumParser
      attr_reader :datum
      include ActiveModel::Validations

      validate :validations

      def validations
        validates_with validator
      end

      def validator
        @parser.components[:fields].select do |entry|
          entry[:header] == @header
        end.first[:validator]
      end

      def initialize(datum, header, parser)
        @parser = parser
        @header = header
        _parse(datum)

        valid?
      end

      def _parse(datum)
        @datum = datum
      end
    end
  end
end
