require 'csv'
module Parsers
  module CsvLayout
    class LineReader
      def initialize(input)
        @input = input
      end
      def lines
        csv_convert(clean_input(@input))
      end

      protected
      def clean_input(str)
        str.kind_of?(String) ? str.gsub("\r", "\n") : str
      end

      def csv_convert(str)
        CSV.new(str).to_a
      end
    end
  end
end
