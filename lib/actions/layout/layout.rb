module Actions
  module Layout
    class Standard
      DNA_STOCK_PLATE_PURPOSE = 'DNA Stock Plate'
      RNA_STOCK_PLATE_PURPOSE = 'RNA Stock Plate'
      STOCK_PLATE_PURPOSE = 'Stock Plate'
      DNA_ALIQUOT = 'DNA'
      RNA_ALIQUOT = 'RNA'
      TUBE_TO_PLATE_TRANSFERRABLE_PROPERTIES = [:study_name,:aliquotType]


    # Actions
      def initialize(params)
        content = selected_file(params[:asset_group]).data
        csv_parsing(asset_group, Parsers::CsvLayout::CsvParser.new(content))
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
        raise InvalidDataParams.new(error_messages) if error_messages.count > 0

        asset = asset_group.assets.with_fact('a', 'TubeRack').first

        if parser.valid?
          rack = asset
          list_layout = parser.layout
          check_collisions(rack, list_layout, error_messages, error_locations)

          check_racking_barcodes(list_layout, error_messages, error_locations)
          check_tuberacks(asset_group, list_layout, error_messages, error_locations)
        end

        unless error_messages.empty?
          raise InvalidDataParams.new(error_messages)
        end
        if parser.valid?
          updates = parser.parsed_changes.merge(reracking_tubes(asset, parser.layout))

          error_messages.push(asset.validate_rack_content)
          raise InvalidDataParams.new(error_messages) if error_messages.flatten.compact.count > 0
          return updates
        else
          raise InvalidDataParams.new(parser.error_list)
        end
      end

    end
  end
end
