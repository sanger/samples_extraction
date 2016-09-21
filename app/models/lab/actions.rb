module Lab::Actions

  def racking(params)
    #ActiveRecord::Base.transaction do |t|
      facts << params.map do |location, barcode|
        asset = Asset.find_by_barcode!(barcode)
        Fact.create(:predicate => location, :object_asset => asset)
      end
    #end
  end
end
