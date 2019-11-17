module Parsers
  module CsvLayout
    class LocationParser
      include ActiveModel::Validations

      validate :validations

      def validations
        validates_with @parser.components[:location_validator]
      end

      attr_reader :location

      def initialize(line, parser)
        @parser = parser
        _parse(line)

        #valid?
      end

      protected

      def _parse(line)
        begin
          @location = TokenUtil.pad_location(line[0].strip)
        rescue StandardError => e
          errors.add(:location, 'There was an error while parsing the location')
        end
      end

    end
  end
end
