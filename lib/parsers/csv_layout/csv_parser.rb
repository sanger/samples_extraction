require 'parsers/csv_layout/line_parser'
require 'parsers/csv_layout/line_reader'
require 'parsers/csv_layout/barcode_parser'
require 'parsers/csv_layout/location_parser'
require 'parsers/csv_layout/validators/fluidx_barcode_validator'
require 'parsers/csv_layout/validators/location_validator'

module Parsers
  module CsvLayout
    class CsvParser
      include ActiveModel::Validations

      validate :validate_parsed_data
      validate :validate_location_duplication
      validate :validate_tube_duplication

      attr_reader :data, :parsed, :parsed_changes, :components, :line_parser

      DEFAULT_COMPONENTS = {
          barcode_parser: Parsers::CsvLayout::BarcodeParser,
          location_parser: Parsers::CsvLayout::LocationParser,
          location_validator: Parsers::CsvLayout::Validators::LocationValidator,
          barcode_validator: Parsers::CsvLayout::Validators::FluidxBarcodeValidator,
          line_parser: Parsers::CsvLayout::LineParser,
          line_reader: Parsers::CsvLayout::LineReader
      }

      def initialize(str, component_defs = {})
        @parsed = false
        @input = str
        @components = self.class::DEFAULT_COMPONENTS.merge(component_defs)
      end

      def parsed?
        @parsed
      end

      def parse
        unless @parsed
          @parsed = false
          @parsed_changes = FactChanges.new
          @line_reader = components[:line_reader].new(@input)
          @line_parser = components[:line_parser].new(@line_reader, self)
          @data ||= @line_parser.parsed_data
          @parsed = true
        end
        @parsed
      end

      def layout
        parse unless @parsed
        @data
      end

      def error_list
        self_error_list = errors.messages.values.flatten
        self_error_list.concat(line_parser.error_list)
      end

      protected

      def validate_parsed_data
        parse unless @parsed
        unless @line_parser.valid?
          errors.add(:base, "The csv contains some errors")
        end
      end

      def validate_tube_duplication
        parse unless @parsed
        if @line_parser.valid?
          unless duplicated(:asset).empty?
            duplicated(:asset).each do |asset|
              errors.add(:base, "The tube with barcode #{asset.barcode} is duplicated in the file")
            end
          end
        end
      end

      def validate_location_duplication
        parse unless @parsed
        if @line_parser.valid?
          unless duplicated(:location).empty?
            duplicated(:location).each do |location|
              errors.add(:base, "The location #{location} is duplicated in the file")
            end
          end
        end
      end

      def duplicated(sym)
        all_elems = layout.map { |obj| obj[sym] }
        all_elems.select do |element|
          (!element.nil?) && (all_elems.count(element) > 1)
        end.uniq.compact
      end

    end
  end
end
