module Parsers
  module CsvMetadata
    class LineParser
      include ActiveModel::Validations
      attr_reader :parsed_content, :header_parser
      validate :validate_parsed_content

      def initialize(input_reader, parser)
        @parser = parser
        @parsed_content = []
        @parsed=false
        @input_reader = input_reader
        valid?
      end

      def parsed_data
        if valid?
          @parsed_content.map do |entry|
            entry[:data_parser].data
          end
        end
      end

      def error_list_for_parser(parser, numline)
        parser.errors.messages.values.map do |msg|
          "At line #{numline}: #{msg[0]}"
        end
      end

      def error_list
        parsed_content.map do |entry|
          error_list_for_parser(entry[:data_parser], entry[:num_line])
        end
      end

      protected

      def validate_parsed_content
        parse unless @parsed
        errors.clear
        @parsed_content.each do |entry|
          unless entry[:data_parser].valid?
            errors.add(:base, "There is an error at line #{entry[:num_line]}")
          end
        end
      end

      def parse
        num_line = 1
        @input_reader.lines.reduce(@parsed_content) do |memo, line|
          if num_line == 1
            @parser.header_parser = @parser.components[:header_parser].new(line, @parser)
          else
            unless is_empty_line?(line)
              data_parser = @parser.components[:data_parser].new(line, @parser)
              memo.push(num_line: num_line, data_parser: data_parser)
            end
          end
          num_line = num_line+1
          memo
        end
        @parsed = true

        parsed_data
      end

      def is_empty_line?(line)
        (line.nil? || (line.length == 0) || line.all?(&:nil?))
      end
    end
  end
end
