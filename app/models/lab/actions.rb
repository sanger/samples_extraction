module Lab::Actions

  class InvalidDataParams < StandardError
    attr_accessor :error_messages
  end

  def racking(step_type, params)
    error_messages = []
    list = params["racking"].map do |location, barcode|
      asset = Asset.find_by_barcode(barcode)
      unless asset
        error_messages.push("Barcode #{barcode} scanned at #{location} is not in the database")
      end
      Fact.new(:predicate => location, :object_asset => asset) if asset
    end
    if error_messages.empty?
      ActiveRecord::Base.transaction do |t|
        asset_group.assets.each do |rack|
          rack.facts << list
        end
      end
    else
      raise InvalidDataParams,  error_messages.join('\n')
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
      raise InvalidDataParams,  pairing.error_messages.join('\n')
    end

  end
end
