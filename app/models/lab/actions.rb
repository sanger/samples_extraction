require 'parsers/csv_layout'
require 'parsers/csv_layout_with_tube_creation'
require 'parsers/csv_order'
require 'parsers/symphony'

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

  def unrack_tubes(list_layout, destination_rack=nil, step=nil)
    facts_to_add = []
    facts_to_destroy = []

    previous_racks = []
    tubes = list_layout.map{|obj| obj[:asset]}.compact
    return if tubes.empty?
    tubes_ids = tubes.map(&:id)
    tubes_list = Asset.where(id: tubes_ids).includes(:facts)
    tubes_list.each_with_index do |tube, index|
      location_facts = tube.facts.with_predicate('location')
      unless location_facts.empty?
        location = location_facts.first.object
        facts_to_destroy.push(tube.facts.with_predicate('location'))
      end
      tube.facts.with_predicate('parent').each do |parent_fact|
        previous_rack = parent_fact.object_asset
        unless (previous_racks.include?(previous_rack))
          previous_racks.push(previous_rack)
          facts_to_destroy.push(previous_rack.facts.with_predicate('contains').where(object_asset_id: tubes_ids))
        end

        if destination_rack
          rerack = Asset.new
          facts_to_add.push([rerack, 'a', 'Rerack'])
          facts_to_add.push([rerack, 'tube', tube])
          facts_to_add.push([rerack, 'previousParent', previous_rack])
          facts_to_add.push([rerack, 'previousLocation', location])
          facts_to_add.push([rerack, 'location', list_layout[index][:location]])
          facts_to_add.push([destination_rack, 'rerack', rerack])
        end

        facts_to_destroy.push(parent_fact)
      end
    end
    remove_facts(facts_to_destroy)
    create_facts(facts_to_add)
  end

  def clean_rack(rack, step)
    remove_facts(facts.with_predicate('contains'))
  end

  def rack_tubes(rack, list_layout, step=nil)
    #ActiveRecord::Base.transaction do |t|
      unrack_tubes(list_layout, rack, step)

      facts_to_add = []
      facts_to_remove = []

      list_layout.each do |l|
        location = l[:location]
        tube = l[:asset]
        next unless tube
        facts_to_remove.push(tube.facts.with_predicate('location'))
        facts_to_add.push([tube, 'location', location])
        facts_to_add.push([tube, 'parent', rack])
        facts_to_add.push([rack, 'contains', tube])
      end
      remove_facts(facts_to_remove.flatten)
      create_facts(facts_to_add)
    #end
  end

  def params_to_list_layout(params)
    params.map do |location, barcode|
      asset = Asset.find_or_import_asset_with_barcode(barcode)
      {
        :location => location, 
        :asset => asset,
        :barcode => barcode
      }
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

  def check_tuberacks(list_layout, error_messages, error_locations)
    if asset_group.assets.with_fact('a', 'TubeRack').empty?
      error_messages.push("No TubeRacks found to perform the racking process")
    end    
  end

  def check_types_for_racking(list_layout, step_type, error_messages, error_locations)
    unless step_type.compatible_with?(list_layout.map{|obj| obj[:asset]}.concat(asset_group.assets).sort.uniq)
      error_messages.push("Some of the assets provided have an incompatible type with the racking step defined")
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

  def racking(step_type, params)
    error_messages = []
    error_locations = []

    check_duplicates(params["racking"], error_messages, error_locations)

    unless error_messages.empty?
      raise InvalidDataParams.new(error_messages, error_locations)
    end

    list_layout = params_to_list_layout(params["racking"])
    rack = asset_group.assets.with_fact('a', 'TubeRack').uniq.first

    check_collisions(rack, list_layout, error_messages, error_locations)

    check_racking_barcodes(list_layout, error_messages, error_locations)
    check_tuberacks(list_layout, error_messages, error_locations)
    check_types_for_racking(list_layout, step_type, error_messages, error_locations)

    if error_messages.empty?
      
      rack_tubes(rack, list_layout)
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

  def csv_parsing(content, class_type)
    error_messages = []
    error_locations = []
    parser = class_type.new(content, self)

    if activity.asset_group.assets.with_fact('a', 'TubeRack').empty?
      error_messages.push("No TubeRacks found to perform the layout process")
    end
    if activity.asset_group.assets.with_fact('a', 'TubeRack').count > 1
      error_messages.push("Too many TubeRacks found to perform the layout process")
    end
    raise InvalidDataParams.new(error_messages) if error_messages.count > 0

    asset = activity.asset_group.assets.with_fact('a', 'TubeRack').first

    if parser.valid?
      rack = asset
      list_layout = parser.layout
      check_collisions(rack, list_layout, error_messages, error_locations)

      check_racking_barcodes(list_layout, error_messages, error_locations)
      check_tuberacks(list_layout, error_messages, error_locations)
      #check_types_for_racking(list_layout, step_type, error_messages, error_locations)
    end

    unless error_messages.empty?
      raise InvalidDataParams.new(error_messages)
    end

    if parser.valid?
      ActiveRecord::Base.transaction do |t|
        unless rack_tubes(asset, parser.layout, self)# parser.add_facts_to(asset, self)
          raise InvalidDataParams.new(parser.errors.map{|e| e[:msg]}) 
        end

        error_messages.push(asset.validate_rack_content)
        raise InvalidDataParams.new(error_messages) if error_messages.flatten.compact.count > 0
      end
    else
      raise InvalidDataParams.new(parser.errors.map{|e| e[:msg]})
    end
  end

  def file
    asset_group.uploaded_files.first
  end

  def rack_layout
    csv_parsing(file.data, Parsers::CsvLayout)
  end

  def rack_layout_creating_tubes
    csv_parsing(file.data, Parsers::CsvLayoutWithTubeCreation)
  end

  def samples_symphony(step_type, params)
    rack = activity.asset_group.assets.with_fact('a', 'TubeRack').first
    msgs = Parsers::Symphony.parse(params[:file].read, rack)
    raise InvalidDataParams.new(msgs) if msgs.length > 0
  end

end
