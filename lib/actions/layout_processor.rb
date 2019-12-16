require 'parsers/csv_layout/csv_parser'
require 'parsers/csv_layout/barcode_creatable_parser'
require 'parsers/csv_layout/validators/any_barcode_validator'
require 'fact_changes'
require 'actions/layout/invalid_data_params'
require 'actions/layout/racking'
require 'actions/layout/unracking'

module Actions
  class LayoutProcessor
    TUBE_TO_RACK_TRANSFERRABLE_PROPERTIES = [:study_name,:aliquotType]

    include Actions::Layout::Racking
    include Actions::Layout::Unracking

    attr_reader :parser, :content, :asset_group

    # Actions
    def initialize(params)
      if params[:asset_group]
        @asset_group = params[:asset_group]
        @content = selected_file(asset_group).data
        @parser = Parsers::CsvLayout::CsvParser.new(content, params)
      end
    end

    def reracking_tubes(rack, list_layout)
      FactChanges.new.tap do |updates|
        tubes = list_layout.map{|o| o[:asset]}.compact
        return updates unless tubes.length > 0
        updates.merge(changes_for_tubes_on_unrack(tubes))
        updates.merge(changes_for_racks_on_unrack(tubes))
        updates.merge(changes_for_rack_tubes(list_layout, rack))
      end
    end

    def changes
      csv_parsing(asset_group, parser)
    end

    def csv_parsing(asset_group, parser)
      error_messages = []
      error_locations = []

      if asset_group.assets.with_fact('a', 'TubeRack').empty?
        error_messages.push("No TubeRacks found to perform the layout process")
      end
      if asset_group.assets.with_fact('a', 'TubeRack').count > 1
        error_messages.push("Too many TubeRacks found to perform the layout process")
      end
      raise Actions::Layout::InvalidDataParams.new(error_messages) if error_messages.count > 0

      asset = asset_group.assets.with_fact('a', 'TubeRack').first

      if parser.valid?
        rack = asset
        list_layout = parser.layout
        check_collisions(rack, list_layout, error_messages, error_locations)

        check_racking_barcodes(list_layout, error_messages, error_locations)
        check_tuberacks(asset_group, list_layout, error_messages, error_locations)
      end

      unless error_messages.empty?
        raise Actions::Layout::InvalidDataParams.new(error_messages)
      end
      if parser.valid?
        updates = parser.parsed_changes.merge(reracking_tubes(asset, parser.layout))

        error_messages.push(asset.validate_rack_content)
        raise Actions::Layout::InvalidDataParams.new(error_messages) if error_messages.flatten.compact.count > 0
        return updates
      else
        raise Actions::Layout::InvalidDataParams.new(parser.error_list)
      end
    end

    def get_duplicates(list)
      list.reduce({}) do |memo, element|
        memo[element] = 0 unless memo[element]
        memo[element]+=1
        memo
      end.each_pair.select{|key, count| count > 1}
    end

    def check_duplicates(params, error_messages, error_locations)
      duplicated_locations = get_duplicates(params.map{|location, barcode| location})
      duplicated_assets = get_duplicates(params.map{|location, barcode| barcode})

      duplicated_locations.each do |location, count|
        error_locations.push(location)
        error_messages.push("Location #{location} is appearing #{count} times")
      end

      duplicated_assets.each do |barcode, count|
        #error_locations.push(barcode)
        error_messages.push("Asset #{barcode} is appearing #{count} times")
      end
    end

    def check_racking_barcodes(list_layout, error_messages, error_locations)
      list_layout.each do |obj|
        location = obj[:location]
        asset = obj[:asset]
        barcode = obj[:barcode]
        if (asset.nil? && !barcode.nil? && !barcode.starts_with?('F'))
          error_locations.push(location)
          error_messages.push("Barcode #{barcode} scanned at #{location} is not in the database")
        end
      end
    end

    def check_tuberacks(asset_group, list_layout, error_messages, error_locations)
      if asset_group.assets.with_fact('a', 'TubeRack').empty?
        error_messages.push("No TubeRacks found to perform the racking process")
      end
    end

    def check_collisions(rack, list_layout, error_messages, error_locations)
      tubes_for_rack = rack.facts.with_predicate('contains').map(&:object_asset)
      tubes_for_rack.each do |tube|
        tube_location = tube.facts.with_predicate('location').first.object
        list_layout.each do |obj|
          next unless obj[:asset]
          if (tube_location == obj[:location])
            if (obj[:asset] != tube)
              error_messages.push(
                "Tube #{obj[:asset].barcode} cannot be put at location #{obj[:location]} because the tube #{tube.barcode || tube.uuid} is there"
                )
            end
          end
        end
        unless (list_layout.map{|obj| obj[:asset]}.include?(tube))
          # Remember that the tubes needs to be always in a rack. They cannot be interchanged
          # in between racks
          error_messages.push(
                "Missing tube!! Any tube already existing in the rack can't disappear from its defined layout without being reracked before. Tube #{tube.barcode || tube.uuid} should be present in the rack at location #{tube_location} but is missed from the rack."
          )
        end
      end

    end

    def selected_file(asset_group)
      asset_group.uploaded_files.first
    end

    def clean_rack(rack)
      remove_facts(facts.with_predicate('contains'))
    end
  end
end
