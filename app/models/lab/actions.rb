module Lab::Actions

  class InvalidDataParams < StandardError
    attr_accessor :error_params

    def initialize(message = nil, error_params = nil)
      super(html_error_message(message))
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
        asset = Asset.find_by_barcode(barcode)
        unless asset
          error_locations.push(location)
          error_messages.push("Barcode #{barcode} scanned at #{location} is not in the database")
        end
        Fact.new(:predicate => location, :object_asset => asset) if asset
      end
    end
    if error_messages.empty?
      ActiveRecord::Base.transaction do |t|
        asset_group.assets.each do |rack|
          rack.facts << list.compact
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
