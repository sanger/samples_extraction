module Asset::Export

  def update_sequencescape(print_config, user)
    instance = SequencescapeClient.find_by_uuid(uuid)
    unless instance
      instance = SequencescapeClient.create_plate(class_name, {}) if class_name
    end
    SequencescapeClient.update_extraction_attributes(instance, attributes_to_update, user.username)
    facts.each {|f| f.update_attributes!(:up_to_date => true)}
    old_barcode = barcode
    update_attributes(:uuid => instance.uuid, :barcode => instance.barcode.ean13)
    add_facts(Fact.create(:predicate => 'beforeBarcode', :object => old_barcode))
    facts.with_predicate('barcodeType').each(&:destroy)
    add_facts(Fact.create(:predicate => 'barcodeType', :object => 'SequencescapePlate'))
    print(print_config, user.username) if old_barcode != barcode
  end


  def attributes_to_update
    {
      :reracks => facts.with_predicate('contains').map(&:object_asset).map do |well|
        memo = []
        if well.facts.has_predicate?('previousParent')
          well.facts.with_predicate('previousParent').each_with_index do |previous_parent_fact, idx|
            memo.push({
              previous_plate_uuid: previous_parent_fact.object_asset.uuid,
              previous_location: well.facts.with_predicate('previousLocation')[idx].object,
              actual_plate_uuid: self.uuid,
              actual_location: well.facts.with_predicate('location').first.object
            })
          end
        end
        memo
      end.flatten.compact,
      :wells => facts.with_predicate('contains').map(&:object_asset).map do |well|
        unless well.nil? || well.facts.nil?
          well.facts.reduce({}) do |memo, fact|
            if (['sample_tube'].include?(fact.predicate))
              memo["#{fact.predicate}_uuid"] = fact.object_asset.uuid
            end

            if (['location', 'aliquotType', 'sanger_sample_id',
              'sanger_sample_name', 'sample_uuid'].include?(fact.predicate))
              memo[fact.predicate] = fact.object
            end
            memo
          end
        end
      end
    }
  end
end
