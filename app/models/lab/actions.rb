require 'parsers/csv_layout'
require 'parsers/csv_layout_with_tube_creation'
require 'parsers/csv_order'

module Lab::Actions

  class InvalidDataParams < StandardError
    attr_accessor :error_params

    def initialize(message = nil, error_params = nil)
      super(html_error_message([message].flatten))
      @error_params = error_params
    end

    def html_error_message(error_messages)
      ['<ul>', error_messages.map do |msg|
        ['<li>',msg,'</li>']
      end, '</ul>'].flatten.join('')
    end

  end

  def racking(step_type, params)
    error_messages = []
    error_locations = []
    list = params["racking"].map do |location, barcode|
      unless barcode.empty?
        asset = Asset.find_or_import_asset_with_barcode(barcode)
        unless asset
          error_locations.push(location)
          error_messages.push("Barcode #{barcode} scanned at #{location} is not in the database")
        end
        [location, asset] if asset
      end
    end.compact
    if asset_group.assets.with_fact('a', 'TubeRack').empty?
      error_messages.push("No TubeRacks found to perform the racking process")
    end
    unless step_type.compatible_with?(list.map{|l,a| a}.concat(asset_group.assets).sort.uniq)
      error_messages.push("Some of the assets provided have an incompatible type with the racking step defined")
    end
    if error_messages.empty?

      ActiveRecord::Base.transaction do |t|
        racks = asset_group.assets.with_fact('a', 'TubeRack').uniq
        racks.each do |rack|
          rack.facts.with_predicate('contains').each do |f|
            f.object_asset.facts.with_predicate('parent').each(&:destroy)
            f.destroy
          end
        end
        racks = asset_group.assets.with_fact('a', 'TubeRack').uniq
        racks.each do |rack|
          list.each do |l|
            location, tube = l[0], l[1]
            Fact.where(:predicate => 'contains', :object_asset => tube).each(&:destroy)
            tube.add_facts(Fact.create(:predicate => 'location', :object => location))
            tube.add_facts(Fact.create(:predicate => 'parent', :object_asset => rack))
            rack.add_facts(Fact.create(:predicate => 'contains', :object_asset => tube))
          end
        end
      end
    else
      raise InvalidDataParams.new(error_messages, error_locations)
    end
  end

  def linking(step_type, params)
    return if params.nil?
    pairing = Pairing.new(params["pairings"], step_type)

    if pairing.valid?
      ActiveRecord::Base.transaction do |t|
        pairing.each_pair_assets do |pair_assets|
          progress_with({:assets => pair_assets, :state => 'in_progress'})
        end
      end
    else
      raise InvalidDataParams, pairing.error_messages
    end
  end

  def csv_parsing(step_type, params, class_type)
    error_messages = []
    parser = class_type.new(params[:file].read)

    if activity.asset_group.assets.with_fact('a', 'TubeRack').empty?
      error_messages.push("No TubeRacks found to perform the layout process")
    end
    if activity.asset_group.assets.with_fact('a', 'TubeRack').count > 1
      error_messages.push("Too many TubeRacks found to perform the layout process")
    end
    raise InvalidDataParams.new(error_messages) if error_messages.count > 0

    asset = activity.asset_group.assets.with_fact('a', 'TubeRack').first

    if parser.valid?
      ActiveRecord::Base.transaction do |t|
        raise InvalidDataParams.new(parser.errors.map{|e| e[:msg]}) unless parser.add_facts_to(asset, self)

        error_messages.push(asset.validate_rack_content)
        raise InvalidDataParams.new(error_messages) if error_messages.flatten.compact.count > 0
      end
    else
      raise InvalidDataParams.new(parser.errors.map{|e| e[:msg]})
    end
  end

  def layout(step_type, params)
    csv_parsing(step_type, params, Parsers::CsvLayout)
  end

  def layout_creating_tubes(step_type, params)
    csv_parsing(step_type, params, Parsers::CsvLayoutWithTubeCreation)
  end

  def order_symphony(step_type, params)
    csv_parsing(step_type, params, Parsers::CsvOrder)
  end

end
