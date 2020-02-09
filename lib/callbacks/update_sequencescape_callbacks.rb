module Callbacks
  class UpdateSequencescapeCallbacks < Callback
    on_keep_property('pushTo', :update_sequencescape)
    on_add_property('pushTo', :pushed_to_callback)

    def self.pushed_to_callback(tuple, updates, step)
      if tuple[:object] == 'Sequencescape'
        update_sequencescape(tuple[:asset], updates, step)
      end
    end

    def self.update_sequencescape(asset, updates, step)
      instance = _update_remote!(asset, updates)

      if instance
        updates.merge(_update_uuid(asset, instance))
        updates.merge(_update_barcode(asset, instance))
        updates.merge(_update_remote_digest(asset))
        updates.merge(_update_purpose(asset))

        updates.merge(_update_wells(asset, instance))
      end
    end

    def self._update_barcode(asset, instance)
      FactChanges.new.tap do |updates|
        if asset.barcode
          updates.remove_where(asset, 'barcode', asset.barcode)
          updates.add(asset, 'beforeBarcode', asset.barcode)
        end
        updates.add(asset, 'barcode', code39_barcode(instance))
        updates.remove(asset.facts.with_predicate('barcodeType'))
        updates.add(asset, 'barcodeType', 'SequencescapePlate')
      end
    end

    def self._update_uuid(asset, instance)
      FactChanges.new.tap do |updates|
        updates.remove_where(asset, 'uuid', asset.uuid)
        updates.add_remote(asset, 'uuid', instance.uuid, literal: true)
      end
    end

    def self._update_remote_digest(asset)
      FactChanges.new.tap do |updates|
        updates.remove_where(asset, 'remote_digest', asset.remote_digest) if asset.remote_digest
        updates.add(asset, 'remote_digest', 'initial_digest')
      end
    end

    def self._update_purpose(asset)
      FactChanges.new.tap do |updates|
        updates.add_remote(asset, 'purpose', asset.class_name) if asset.class_name && !asset.class_name.empty?
      end
    end

    def self._update_remote!(asset, updates)
      instance = nil
      begin
        instance = SequencescapeClient.version_1_find_by_uuid(asset.uuid)
        unless instance
          instance = SequencescapeClient.create_plate(asset.class_name, {}) if asset.class_name
        end
        if duplicate_locations_in_plate?(asset)
          updates.set_errors(["Duplicate locations in asset #{asset.uuid}"])
        else
          attrs = attributes_to_update(asset)
          unless attrs.empty?
            SequencescapeClient.update_extraction_attributes(instance, attrs, step.user.username)
          end
        end
      rescue SocketError
        updates.set_errors(['Sequencescape connection - Network connectivity issue'])
      rescue Errno::ECONNREFUSED => e
        updates.set_errors(['Sequencescape connection - The server is down.'])
      rescue Timeout::Error => e
        updates.set_errors(['Sequencescape connection - Timeout error occurred.'])
      rescue StandardError => err
        updates.set_errors(['Sequencescape connection - There was an error while updating Sequencescape'+err.backtrace.to_s])
      end
      instance
    end

    def self._update_wells(asset, instance)
      FactChanges.new.tap do |updates|
        instance.wells.each do |well|
          fact = fact_well_at(asset, well.location)
          if fact
            w = fact.object_asset
            if w && w.uuid != well.uuid
              updates.remove_where(w, 'uuid', w.uuid)
              updates.add_remote(w, 'uuid', well.uuid, literal: true)
            end
          end
        end
      end
    end

    def self.fact_well_at(asset, location)
      asset.facts.with_predicate('contains').select do |f|
        if f.object_asset
          TokenUtil.unpad_location(f.object_asset.facts.with_predicate('location').first.object) == TokenUtil.unpad_location(location)
        end
      end.first
    end

    def self.duplicate_locations_in_plate?(asset)
      locations = asset.facts.with_predicate('contains').map(&:object_asset).map do |a|
        a.facts.with_predicate('location').map(&:object)
      end.flatten.compact
      (locations.uniq.length != locations.length)
    end

    def self.attributes_to_update(asset)
      asset.facts.with_predicate('contains').map(&:object_asset).map do |well|
        racking_info(well)
      end.compact
    end

    def self.pushed_to_sequencescape?(well)
      !well.remote_digest.nil?
    end

    def self.code39_barcode(instance)
      prefix = instance.barcode.prefix
      number = instance.barcode.number
      SBCF::SangerBarcode.new(prefix:prefix, number:number).human_barcode
    end

    def self.racking_info(well)
      # If it was already in SS, always export it
      if pushed_to_sequencescape?(well)
        return {
          uuid: well.uuid,
          location: TokenUtil.unpad_location(well.facts.with_predicate('location').first.object)
        }
      end

      # Do not export any well information unless it has a sample defined for it
      return nil unless well.has_sample?

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
end
