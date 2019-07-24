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

        pad_location if valid?
        valid?
      end

      protected
      def _parse(line)
        begin
          @location = line[0].strip
        rescue StandardError => e
          errors.add(:location, 'There was an error while parsing the location')
        end
      end
      def pad_location
        parts = @location.match(@parser.components[:location_validator]::LOCATION_REGEXP)
        letter = parts[1]
        number = parts[2]
        number = TokenUtil.pad(number,"0",2) unless number.length==2
        @location="#{letter}#{number}"
      end
    end
  end
end
