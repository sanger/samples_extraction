module Parsers
  module CsvMetadata
    class HeaderParser
      attr_reader :headers
      include ActiveModel::Validations

      validate :validations

      def validations
        validates_with @parser.components[:header_validator]
      end

      def initialize(line, parser)
        @parser = parser
        _parse(line)

        valid?
      end

      def _parse(line)
        @headers=line.map{|header| header.strip }
      end
    end
  end
end
