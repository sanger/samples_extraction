require 'csv'

module Parsers
  class CsvOrder
    attr_reader :csv_parser, :errors, :data, :parsed

    def initialize(str)
      @csv_parser = CSV.new(str)
      @errors = []
      @parsed = false
    end

    def parsed?
      @parsed
    end

    def duplicated(sym)
      return [] unless @data
      all_elems = @data.map{|obj| obj[sym]}
      all_elems.select do |element|
        all_elems.count(element) > 1
      end.uniq.compact
    end

    def parse
      @data ||= @csv_parser.to_a.map do |line|
        obj = {:asset => nil}
        unless line.empty?
          barcode = line[0]
          asset = Asset.find_by_barcode(barcode)
          @errors.push(:msg => "Cannot find the barcode #{barcode}") if asset.nil?
          obj[:asset] = asset
        end
        obj
      end

      unless duplicated(:asset).empty?
        duplicated(:asset).each do |asset|
          @errors.push(:msg => "The tube with barcode #{asset.barcode} is duplicated in the file")
        end
      end
      unless duplicated(:location).empty?
        duplicated(:location).each do |location|
          @errors.push(:msg => "The location #{location} is duplicated in the file")
        end
      end
      @parsed = true
      valid?
    end

    def valid?
      parse unless @parsed
      @data && @errors.empty?
    end

    def sample_tubes
      @data if valid?
    end

    def locations_by_column
      12.times.map do |col|
        ('A'..'H').to_a.map do |l|
          "#{l}#{col+1}"
        end
      end.flatten
    end

    def add_facts_to(rack, step)
      if valid?
        rack_tubes_by_location = rack.facts.with_predicate('contains').map(&:object_asset).reduce({}) do |memo, tube|
          location = tube.facts.with_predicate('location').first.object
          memo[location] = tube
          memo
        end

        locations_by_column.each_with_index do |location, index|
          if index < sample_tubes.length
            sample_tube = sample_tubes[index][:asset]
            if sample_tube
              tube = rack_tubes_by_location[location]
              sample_tube.add_facts(Fact.create(:predicate => 'transfer', :object_asset => tube))
            end
          end
        end
      end
    end

  end
end
