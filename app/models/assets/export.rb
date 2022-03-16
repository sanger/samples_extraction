module Assets::Export
  class DuplicateLocations < StandardError; end

  def update_sequencescape(_print_config, user, _step)
    FactChanges.new.tap do |updates|
      begin
        # remote (Sequencescape) updates
        instance = SequencescapeClient.version_1_find_by_uuid(uuid)
        instance = create_remote_asset unless instance
        create_or_update_remote_contained_assets(instance, user) unless attributes_to_send.empty?

        # local (Samples Extraction) updates
        old_barcode = barcode
        update_attributes(:uuid => instance.uuid, :barcode => code39_barcode(instance))

        update_wells(instance, updates)

        updates.add(self, 'beforeBarcode', old_barcode) if old_barcode
        updates.add_remote(self, 'purpose', class_name) if class_name
        updates.remove(facts.with_predicate('barcodeType'))
        updates.add(self, 'barcodeType', 'SequencescapePlate')

        mark_as_updated(updates)
        mark_to_print(updates) if old_barcode != barcode
      rescue SocketError
        updates.set_errors(['Sequencescape connection - Network connectivity issue'])
      rescue Errno::ECONNREFUSED => e
        updates.set_errors(['Sequencescape connection - The server is down.'])
      rescue Timeout::Error => e
        updates.set_errors(['Sequencescape connection - Timeout error occurred.'])
      rescue StandardError => err
        updates.set_errors(['Sequencescape connection - There was an error while updating Sequencescape', err.message, err.backtrace.to_s])
      end
    end
  end

  def create_remote_asset
    SequencescapeClient.create_plate(class_name, {}) if class_name
  end

  def create_or_update_remote_contained_assets(instance, user)
    # create the (remote) aliquots against the wells created above, or rearrange them (re-racking)
    SequencescapeClient.update_extraction_attributes(instance, attributes_to_send, user.username)
  end

  def mark_to_print(updates)
    updates.add(self, 'is', 'readyForPrint')
  end

  def code39_barcode(instance)
    prefix = instance.barcode.prefix
    number = instance.barcode.number
    SBCF::SangerBarcode.new(prefix: prefix, number: number).human_barcode
  end

  def update_wells(instance, updates)
    instance.wells.each do |well|
      fact = fact_well_at(well.location)
      if fact
        w = fact.object_asset
        if w && w.uuid != well.uuid
          w.update_attributes(uuid: well.uuid)
          fact.update_attributes(is_remote?: true)
        end
      end
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

  def attributes_to_send
    raise DuplicateLocations if duplicate_locations_in_plate?

    facts.with_predicate('contains').map(&:object_asset).filter_map do |well|
      attributes_to_send_for_well(well)
    end
  end

  def has_sample?
    has_predicate_with_value?('supplier_sample_name') ||
      has_relation_with_value?('sample_tube') ||
      has_predicate_with_value?('sample_uuid')
  end

  def attributes_to_send_for_well(well)
    # If it was already in SS, always export it
    if well.has_literal?('pushedTo', 'Sequencescape')
      return {
        uuid: well.uuid,
        location: TokenUtil.unpad_location(well.facts.with_predicate('location').first.object)
      }
    end

    # Do not export any well information unless it has a sample defined for it
    return nil unless well.has_sample?

    # extract the 'facts' that we want to send to Sequencescape for creation of wells
    well.facts.reduce({}) do |memo, fact|
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
