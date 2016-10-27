require 'csv'

module Parsers
  class CsvLayout
    attr_reader :csv_parser, :errors, :data, :parsed

    def create_tubes?
      false
    end

    def initialize(str)
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
        all_elems.count(element) > 1
      end.uniq
    end

    def location_str(location)
      location[0] + (location[1..location.length].to_i.to_s)
    end

    def builder(barcode)
      if create_tubes?
        Asset.find_or_create_by(:barcode => barcode)
      else
        Asset.find_by_barcode(barcode)
      end
    end

    def valid_location?(location)
      !!location.match(/[A-H]\d\d/)
    end

    def parse
      @data ||= @csv_parser.to_a.map do |line|
        location, barcode = line[0], line[1]
        asset = builder(barcode)
        @errors.push(:msg => "Invalid location") unless valid_location?(location)
        @errors.push(:msg => "Cannot find the barcode #{barcode}") if asset.nil?
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
      valid?
    end

    def valid?
      parse unless @parsed
      @data && @errors.empty?
    end


    def add_facts_to(asset, step)
      if valid?
        facts_to_remove = asset.facts.with_predicate('contains').map do |f|
          [
            f.object_asset.facts.with_predicate('parent'),
            f.object_asset.facts.with_predicate('location'),
            f
            ].flatten.compact
        end.flatten.each do |f|
          f.set_to_remove_by(step.id)
        end
        facts_to_add = @data.map do |obj|
          [obj[:asset].facts.with_predicate(:location), obj[:asset].facts.with_predicate(:parent)].flatten.each do |f|
            f.set_to_remove_by(step.id)
          end

          obj[:asset].add_facts([
            Fact.create(:predicate => 'location', :object => obj[:location], :to_add_by => step.id),
            Fact.create(:predicate => 'parent', :object_asset => asset, :to_add_by => step.id)
          ])
          Fact.create(:predicate => 'contains', :object_asset => obj[:asset], :to_add_by => step.id)
        end
        asset.add_facts(facts_to_add) if valid?
        return valid?
      end
      return false
    end
  end
end
