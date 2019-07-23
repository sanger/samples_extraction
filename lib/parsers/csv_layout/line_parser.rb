module Parsers
  module CsvLayout
    class LineParser
      include ActiveModel::Validations

      validate :validate_parsed_content

      def initialize(input_reader, parser)
        @parser = parser
        @parsed_content = []
        @parsed=false
        @input_reader = input_reader
      end

      def parsed_data
        if valid?
          @parsed_content.map do |entry|
            {
              location: entry[:location_parser].location,
              asset: entry[:barcode_parser].asset
            }
          end
        end
      end

      protected

      def validate_parsed_content
        parse unless @parsed
        errors.clear
        @parsed_content.each do |entry|
          unless entry[:location_parser].valid? && entry[:barcode_parser].valid?
            errors.add(:base, "There is an error at line #{entry[:num_line]}")
          end
        end
      end

      def parse
        num_line = 0
        @input_reader.lines.reduce(@parsed_content) do |memo, line|
          unless is_empty_line?(line)
            barcode_parser = @parser.components[:barcode_parser].new(line, @parser)
            unless barcode_parser.no_read_barcode?
              location_parser = @parser.components[:location_parser].new(line, @parser)
              memo.push({
                location_parser: location_parser,
                barcode_parser: barcode_parser,
                num_line: num_line
              })
            end
          end
          num_line = num_line+1
          memo
        end
        @parsed = true

        parsed_data
      end

      def is_empty_line?(line)
        (line.nil? || (line.length == 0))
      end
    end
  end
end
