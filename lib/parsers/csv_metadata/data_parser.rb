module Parsers
  module CsvMetadata
    class DataParser
      attr_reader :data
      include ActiveModel::Validations

      validate :validations

      def validations
        validates_with @parser.components[:data_validator]
      end

      def initialize(line, parser)
        @parser = parser
        _parse(line)

        valid?
      end

      def _parse(line)
        @data = @parser.header_parser.headers.zip(line).reduce({}) do |memo, data_line|
          header = data_line[0]
          value = data_line[1]
          memo[header] = value
          memo
        end
      end
    end
  end
end
