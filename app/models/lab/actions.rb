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
    if error_messages.empty?

      ActiveRecord::Base.transaction do |t|
        racks = asset_group.assets.with_fact('a', 'TubeRack').uniq
        racks.each do |rack|
          rack.facts.with_predicate('contains').each do |f|
            f.object_asset.facts.with_predicate('parent').each(&:destroy)
            f.destroy
          end
        end
        racks.each do |rack|
          list.each do |l|
            location, tube = l[0], l[1]
            tube.facts << Fact.create(:predicate => 'location', :object => location)
            tube.facts << Fact.create(:predicate => 'parent', :object_asset => rack)
            rack.facts << Fact.create(:predicate => 'contains', :object_asset => tube)
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
end
