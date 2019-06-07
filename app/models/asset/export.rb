module Asset::Export


  class DuplicateLocations < StandardError ; end

  def update_sequencescape(print_config, user, step)
    instance = SequencescapeClient.find_by_uuid(uuid)
    unless instance
      instance = SequencescapeClient.create_plate(class_name, {}) if class_name
    end
    unless attributes_to_update.empty?
      SequencescapeClient.update_extraction_attributes(instance, attributes_to_update, user.username)
    end

    #facts.each {|f| f.update_attributes!(:up_to_date => true)}
    old_barcode = barcode
    previous_asset_group_ids = asset_groups.map(&:id)
    update_attributes(:uuid => instance.uuid, :barcode => code39_barcode(instance))

    FactChanges.new.tap do |updates|
      update_plate(instance, updates)

      updates.add(self, 'beforeBarcode', old_barcode) if old_barcode
      updates.add(self, 'purpose', class_name)
      updates.remove(facts.with_predicate('barcodeType'))
      updates.add(self, 'barcodeType', 'SequencescapePlate')

      mark_as_updated(updates)
      mark_to_print(updates) if old_barcode != barcode
    end.apply(step)
    previous_asset_group_ids.each{|a| AssetGroup.find(a).touch }
  end

  def mark_to_print(updates)
    updates.add(self, 'is', 'readyForPrint')
  end

  def code39_barcode(instance)
    prefix = instance.barcode.prefix
    number = instance.barcode.number
    SBCF::SangerBarcode.new(prefix:prefix, number:number).human_barcode
  end

  def update_plate(instance, updates)
    instance.wells.each do |well|
      fact = fact_well_at(well.location)
      if fact
        w = fact.object_asset
        if w && w.uuid != well.uuid
          w.update_attributes(uuid: well.uuid)
          fact.update_attributes(is_remote?: true)
        end
      else
        updates.create_assets([well.uuid])
        updates.add(well.uuid, 'barcodeType', 'NoBarcode')
        updates.add_remote(self, 'contains', well.uuid)
      end
    end
  end

  def fact_well_at(location)
    facts.with_predicate('contains').select do |f|
      if f.object_asset
        to_sequencescape_location(f.object_asset.facts.with_predicate('location').first.object) == to_sequencescape_location(location)
      end
    end.first
  end

  def mark_as_updated(updates)
    updates.add(self, 'pushedTo', 'Sequencescape')
    facts.with_predicate('contains').each do |f|
      if f.object_asset.has_predicate?('sample_tube')
        updates.add(f.object_asset, 'pushedTo', 'Sequencescape')
      end
    end
  end


  def duplicate_locations_in_plate?
    locations = facts.with_predicate('contains').map(&:object_asset).map do |a|
      a.facts.with_predicate('location').map(&:object)
    end.flatten.compact
    (locations.uniq.length != locations.length)
  end

  def attributes_to_update
    raise DuplicateLocations if duplicate_locations_in_plate?
    facts.with_predicate('contains').map(&:object_asset).map do |well|
      racking_info(well)
    end
  end

  def to_sequencescape_location(location)
    loc = location.match(/(\w)(0*)(\d*)/)
    loc[1]+loc[3]
  end

  def racking_info(well)
    if well.has_literal?('pushedTo', 'Sequencescape')
      return {
        uuid: well.uuid,
        location: to_sequencescape_location(well.facts.with_predicate('location').first.object)
      }
    end
    well.facts.reduce({}) do |memo, fact|
      if (['sample_tube'].include?(fact.predicate))
        memo["#{fact.predicate}_uuid".to_sym] = fact.object_asset.uuid
      end
      if (fact.predicate == 'location')
        memo[fact.predicate.to_sym] = to_sequencescape_location(fact.object)
      end
      if (['aliquotType', 'sanger_sample_id',
        'sanger_sample_name', 'sample_uuid'].include?(fact.predicate))
        memo[fact.predicate.to_sym] = fact.object
      end
      memo
    end
  end

end
