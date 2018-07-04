require 'csv'

module Parsers
  class CsvLayout
    attr_reader :csv_parser, :errors, :data, :parsed, :step

    def create_tubes?
      false
    end

    def initialize(str, step)
      @step = step
      @csv_parser = CSV.new(str)
      @errors = []
      @parsed = false
    end

    def parsed?
      @parsed
    end

    def duplicated(sym)
      all_elems = @data.map{|obj| obj[sym]}
      all_elems.select do |element|
        (!element.nil?) && (all_elems.count(element) > 1)
      end.uniq.compact
    end

    def location_str(location)
      location[0] + (location[1..location.length].to_i.to_s)
    end

    def builder(barcode, updater)
      if create_tubes?
        asset = Asset.find_by_barcode(barcode)
        unless asset
          updater.add(Asset.new(:barcode => barcode) , 'a', 'Tube')
        end
      else
        asset = Asset.find_by_barcode(barcode)
      end
      asset
    end

    def valid_location?(location)
      !!location.match(/[A-H]\d\d/)
    end

    def valid_fluidx_barcode?(barcode)
      barcode.start_with?('F')
    end

    def no_read_barcode?(barcode)
      barcode.start_with?('No Read')
    end    

    def parse
      updater = FactChanges.new
      @data ||= @csv_parser.to_a.map do |line|
        location, barcode = line[0].strip, line[1].strip
        asset = valid_fluidx_barcode?(barcode) ? builder(barcode, updater) : nil
        @errors.push(:msg => "Invalid Fluidx tube barcode format #{barcode}") unless valid_fluidx_barcode?(barcode) || no_read_barcode?(barcode)
        @errors.push(:msg => "Invalid location") unless valid_location?(location)

        if asset.nil? && valid_fluidx_barcode?(barcode)
          @errors.push(:msg => "Cannot find the barcode #{barcode}")
        end

        {
          :location => location_str(location),
          :asset => asset
        }
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
      
      valid?.tap {|val| updater.apply(@step) if val }
    end

    def valid?
      parse unless @parsed
      @data && @errors.empty?
    end

    def layout
      @data
    end

  end
end
