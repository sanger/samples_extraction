module Lab::Actions

  def racking(params)
    ActiveRecord::Base.transaction do |t|
      asset_group.assets.each do |rack|
        rack.facts << JSON.parse(params).map do |location, barcode|
          asset = Asset.find_by_barcode!(barcode)
          Fact.create(:predicate => location, :object_asset => asset)
        end
      end
    end
  end

  def linking(params)
    return if params.nil?
    pairings = JSON.parse(params).values.map do |obj|
      Pairing.new(obj, step_type)
    end

    if pairings.all?(&:valid?)
      ActiveRecord::Base.transaction do |t|
        pairings.each do |pairing|
          progress_with({:assets => pairing.assets, :state => 'in_progress'})
        end
      end
    else
      error_message = pairings.map(&:error_messages).join('\n')
    end

  end
end
