require 'csv'

module Parsers
  class CsvLayout
    attr_reader :csv_parser, :errors, :data, :parsed, :parsed_changes

    LOCATION_REGEXP = /^([A-H])(\d{1,2})$/

    def create_tubes?
      false
    end

    def initialize(str)
      if str.kind_of?(String)
        copy = str.gsub("\r", "\n")
      else
        copy = str
      end
      @csv_parser = CSV.new(copy)
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
          asset = Asset.new(barcode: barcode)
          asset.generate_uuid!
          updater.create_assets([asset])
          updater.add(asset, 'barcode', barcode)
          updater.add(asset , 'a', 'Tube')
          updater.create_asset_groups(["?created_tubes"])
        end
      else
        asset = Asset.find_by_barcode(barcode)
      end
      asset
    end

    def valid_location?(location)
      !location.nil? && !!location.match(LOCATION_REGEXP)
    end

    def valid_fluidx_barcode?(barcode)
      barcode.start_with?('F')
    end

    def no_read_barcode?(barcode)
      barcode.downcase.start_with?('no read')
    end

    def convert_to_location(str)
      if valid_location?(str)
        matches = str.match(LOCATION_REGEXP)
        num = matches[2]
        if (num.length==1)
          num = "0" + num.to_s
        end
        return matches[1] + num.to_s
      end
      return nil
    end

    def validate_tube_barcode_format(barcode)
      unless valid_fluidx_barcode?(barcode) || no_read_barcode?(barcode)
        @errors.push(:msg => "Invalid Fluidx tube barcode format #{barcode}")
      end
    end

    def parse
      updater = FactChanges.new
      @data ||= @csv_parser.to_a.map do |line|
        next if line.nil? || line.length == 0
        location, barcode = convert_to_location(line[0].strip), line[1].strip
        asset = valid_fluidx_barcode?(barcode) ? builder(barcode, updater) : nil

        validate_tube_barcode_format(barcode)

        @errors.push(:msg => "Invalid location") unless valid_location?(location)

        if asset.nil? && valid_fluidx_barcode?(barcode)
          @errors.push(:msg => "Cannot find the barcode #{barcode}")
        end

        {
          :location => location,
          :asset => asset
        }
      end.compact

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
      @parsed_changes = updater
      valid?
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
