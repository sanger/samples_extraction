module Asset::Export

  def update_sequencescape
    instance = SequencescapeClient.find_by_uuid(uuid)
    unless instance
      instance = SequencescapeClient.create_plate(class_name, attrs_for_sequencescape) if class_name
    end
    SequencescapeClient.update_extraction_attributes(instance, attrs_for_sequencescape)
    facts.each {|f| f.update_attributes!(:up_to_date => true)}
    update_attributes(:uuid => instance.uuid, :barcode => instance.barcode.ean13)
  end

end
