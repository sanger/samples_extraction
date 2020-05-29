# Used in the assets model
module Assets::Export
  class DuplicateLocations < StandardError ; end

  # print_config and step arguments don't seem to be used in this method
  def update_sequencescape(_print_config, user, _step)
    FactChanges.new.tap do |updates|
      begin
        instance = find_remote_record
        instance = create_remote_record unless instance

        unless attributes_to_update.empty?
          SequencescapeClient.update_extraction_attributes(instance, attributes_to_update, user.username)
        end

        old_barcode = barcode

        # TODO: barcode is being set to blank because Sequencescape isn't creating a barcode for the tube rack on creation
        update_attributes(:uuid => instance.uuid, :barcode => code39_barcode(instance))

        update_wells(instance) if class_type != 'TubeRack'
        update_racked_tubes(instance) if class_type == 'TubeRack'

        updates.add(self, 'beforeBarcode', old_barcode) if old_barcode
        updates.add_remote(self, 'purpose', class_name) if class_name
        updates.remove(facts.with_predicate('barcodeType'))
        updates.add(self, 'barcodeType', 'SequencescapePlate') # should this change for tube racks?

        mark_as_updated(updates)
        mark_to_print(updates) if old_barcode != barcode
      rescue SocketError
        updates.set_errors(['Sequencescape connection - Network connectivity issue'])
      rescue Errno::ECONNREFUSED => e
        updates.set_errors(['Sequencescape connection - The server is down.'])
      rescue Timeout::Error => e
        updates.set_errors(['Sequencescape connection - Timeout error occurred.'])
      rescue StandardError => err
        updates.set_errors(['Sequencescape connection - There was an error while updating Sequencescape'+err.backtrace.to_s])
      end
    end
  end

  def find_remote_record
    if class_type == 'TubeRack'
      SequencescapeClient.find_by_uuid(uuid)
    else
      SequencescapeClient.version_1_find_by_uuid(uuid)
    end
  end

  def create_remote_record
    if class_type == 'TubeRack'
      SequencescapeClient.create_tube_rack(class_name, {})
    else
      SequencescapeClient.create_plate(class_name, {}) if class_name
    end
  end

  def has_sample?
    has_predicate_with_value?('supplier_sample_name') ||
    has_relation_with_value?('sample_tube') ||
    has_predicate_with_value?('sample_uuid')
  end

  # Below are helper methods used internally in this module
  def mark_to_print(updates)
    updates.add(self, 'is', 'readyForPrint')
  end

  def code39_barcode(instance)
    if class_type == 'TubeRack'
      instance.labware_barcode['human_barcode']
    else
      prefix = instance.barcode.prefix
      number = instance.barcode.number
      SBCF::SangerBarcode.new(prefix:prefix, number:number).human_barcode
    end
  end

  def update_wells(instance)
    # for each remote well
    instance.wells.each do |well|
      # find the fact on the asset which corresponds to that well's location
      fact = fact_well_at(well.location)
      continue unless fact

      # get the equivalent local well
      asset = fact.object_asset
      continue unless asset && asset.uuid != well.uuid

      # update the local well's uuid (when would it have changed?)
      asset.update_attributes(uuid: well.uuid)
      # update fact with is_remote?: true
      fact.update_attributes(is_remote?: true)
    end
  end

  # DRY this and method above?
  # test below manually
  def update_racked_tubes(instance)
    instance.racked_tubes.each do |racked_tube|
      fact = fact_well_at(racked_tube.coordinate)
      continue unless fact

      asset = fact.object_asset
      continue unless asset && asset.uuid != racked_tube.uuid

      asset.update_attributes(uuid: racked_tube.uuid)
      fact.update_attributes(is_remote?: true)
    end
  end

  def fact_well_at(location)
    facts.with_predicate('contains').select do |f|
      if f.object_asset
        TokenUtil.unpad_location(f.object_asset.facts.with_predicate('location').first.object) == TokenUtil.unpad_location(location)
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

    facts.with_predicate('contains').map(&:object_asset).map do |contained_asset|
      racking_info(contained_asset)
    end.compact
  end

  def racking_info(contained_asset)
    # If it was already in SS, always export it
    if contained_asset.has_literal?('pushedTo', 'Sequencescape')
      return {
        uuid: contained_asset.uuid,
        location: TokenUtil.unpad_location(contained_asset.facts.with_predicate('location').first.object)
      }
    end # ...and don't update sample or anything?

    # Do not export any well information unless it has a sample defined for it
    return nil unless contained_asset.has_sample?

    contained_asset.facts.reduce({}) do |memo, fact|
      if (['sample_tube'].include?(fact.predicate))
        memo["#{fact.predicate}_uuid".to_sym] = fact.object_asset.uuid
      end
      if (fact.predicate == 'location')
        memo[fact.predicate.to_sym] = TokenUtil.unpad_location(fact.object)
      end
      if (['aliquotType', 'sanger_sample_id',
        'sanger_sample_name', 'sample_uuid'].include?(fact.predicate))
        memo[fact.predicate.to_sym] = TokenUtil.unquote(fact.object)
      end
      memo
    end
  end
end
