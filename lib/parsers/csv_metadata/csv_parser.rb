require 'parsers/csv_metadata/header_parser'
require 'parsers/csv_metadata/line_parser'
require 'parsers/csv_metadata/data_parser'
require 'parsers/csv_layout/line_reader'
require 'parsers/csv_layout/validators/any_barcode_validator'
require 'parsers/csv_layout/validators/location_validator'
require 'parsers/csv_metadata/validators/data_validator'
require 'parsers/csv_metadata/validators/header_validator'

module Parsers
  module CsvMetadata
    class CsvParser
      include ActiveModel::Validations

      validate :validate_parsed_data

      attr_accessor :header_parser
      attr_reader :data, :parsed, :parsed_changes, :components, :line_parser


      DEFAULT_COMPONENTS = {
        header_parser: Parsers::CsvMetadata::HeaderParser,
        data_parser: Parsers::CsvMetadata::DataParser,
        line_parser: Parsers::CsvMetadata::LineParser,
        line_reader: Parsers::CsvLayout::LineReader,
        header_validator: Parsers::CsvMetadata::Validators::HeaderValidator,
        data_validator: Parsers::CsvMetadata::Validators::DataValidator,

        fields: [
          { header: 'barcode', validator: Parsers::CsvLayout::Validators::AnyBarcodeValidator },
          { header: 'location', validator: Parsers::CsvLayout::Validators::LocationValidator }
          #{ header: 'sample_uuid', validator: Parsers::CsvMetadata::Validators::Uuid },
          #{ header: 'study_uuid', validator: Parsers::CsvMetadata::Validators::Uuid },
          #{ header: 'barcode', validator: Parsers::CsvMetadata::Validators::Barcode },
          #{ header: 'pipeline', validator: Parsers::CsvMetadata::Validators::LongReadPipeline },
          #{ header: 'estimate_of_gb_required', validator: Parsers::CsvMetadata::Validators::Integer },
          #{ header: 'number_of_smrt_cells', validator: Parsers::CsvMetadata::Validators::Integer },
          #{ header: 'cost_code', validator: Parsers::CsvMetadata::Validators::CostCode },
        ]
      }

      def initialize(str, component_defs={})
        @parsed = false
        @input = str
        @components = self.class::DEFAULT_COMPONENTS.merge(component_defs)
        valid?
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

      def metadata
        parse unless @parsed
        @data
      end

      def create_tubes?
        false
      end

      def error_list
        line_parser.error_list
      end

      protected

      def validate_parsed_data
        parse unless @parsed
        unless @line_parser.valid?
          errors.add(:base, "The csv contains some errors")
        end
      end

    end
  end
end
