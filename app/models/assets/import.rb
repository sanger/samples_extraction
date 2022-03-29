module Assets::Import
  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  class RefreshSourceNotFoundAnymore < StandardError; end

  module InstanceMethods
    def json_for_remote(remote_asset)
      distinct = remote_asset.attributes.to_json

      # It would be useful to have a hashcode in the sequencescape client api to know
      # if this message is different from a previous one without needing to traverse
      # all the object finding the change
      # Having a :to_json method that returns a json would be pretty sensible too

      # FOR A PLATE
      if remote_asset.respond_to?(:wells) && remote_asset.wells
        # wells.to_a because wells relation does not act as an array
        wells = remote_asset.wells.to_a
        if wells
          # aliquots.to_a, same reason
          aliquots = wells.compact.map(&:aliquots).map(&:to_a)
          if aliquots
            samples = aliquots.flatten.compact.map { |al| al.sample }
            if samples
              distinct += samples.compact.map(&:attributes).to_json
            end
          end
        end
      end

      # FOR A TUBE
      if remote_asset.respond_to?(:aliquots) && remote_asset.aliquots
        # aliquots.to_a, same reason
        aliquots = remote_asset.aliquots.to_a
        if aliquots
          samples = aliquots.flatten.compact.map { |al| al.sample }
          if samples
            distinct += samples.compact.map(&:attributes).to_json
          end
        end
      end

      # FOR A TUBE RACK
      if remote_asset.respond_to?(:racked_tubes) && remote_asset.racked_tubes
        # to_a because racked_tubes relation does not act as an array
        list_tubes = remote_asset.racked_tubes.map do |racked_tube|
          racked_tube.tube
        end.to_a

        if list_tubes
          # aliquots.to_a, same reason
          aliquots = list_tubes.compact.map(&:aliquots).map(&:to_a)
          if aliquots
            samples = aliquots.flatten.compact.map { |al| al.sample }
            if samples
              distinct += samples.compact.map(&:attributes).to_json
            end
          end
        end
      end

      distinct
    end

    def update_digest_with_remote(remote_asset)
      update_attributes(remote_digest: Digest::MD5::hexdigest(json_for_remote(remote_asset)))
    end

    def changed_remote?(remote_asset)
      Digest::MD5::hexdigest(json_for_remote(remote_asset)) != remote_digest
    end

    def assets_to_refresh
      # We need to destroy also the remote facts of the contained wells on refresh
      [self, facts.with_predicate('contains').map(&:object_asset).select do |asset|
        asset.facts.from_remote_asset.count > 0
      end].flatten
    end

    def is_refreshing_right_now?
      Step.running_with_asset(self).count > 0
    end

    def refresh(fact_changes = nil)
      if is_remote_asset?
        remote_asset = SequencescapeClient::find_by_uuid(uuid)
        raise RefreshSourceNotFoundAnymore unless remote_asset

        refresh_from_remote(fact_changes: fact_changes, remote_asset: remote_asset)
      end
      self
    end

    def refresh_from_remote(remote_asset:, fact_changes: nil)
      return unless changed_remote?(remote_asset)
      return if is_refreshing_right_now?

      @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Refresh'), state: 'running')
      _process_refresh(remote_asset, fact_changes)
    end

    def refresh!(fact_changes = nil)
      if is_remote_asset?
        @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Refresh!!'), state: 'running')
        remote_asset = SequencescapeClient::find_by_uuid(uuid)
        raise RefreshSourceNotFoundAnymore unless remote_asset

        _process_refresh(remote_asset, fact_changes)
      end
      self
    end

    def is_remote_asset?
      facts.from_remote_asset.count > 0
    end

    private

    def _process_refresh(remote_asset, fact_changes)
      fact_changes ||= FactChanges.new
      asset_group = AssetGroup.new
      @import_step.update(asset_group: asset_group)

      begin
        fact_changes.tap do |updates|
          asset_group.update(assets: assets_to_refresh)

          # Removes previous state
          assets_to_refresh.each do |asset|
            updates.remove(asset.facts.from_remote_asset)
          end

          # Loads new state
          self.class.update_asset_from_remote_asset(self, remote_asset, updates)
        end.apply(@import_step)
        @import_step.update(state: 'complete')
        asset_group.touch
      ensure
        @import_step.update(state: 'error') unless @import_step.state == 'complete'
      end
    end
  end

  module ClassMethods
    def import_barcode(barcode)
      @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Import'), state: 'running')
      remote_asset = SequencescapeClient::get_remote_asset(barcode)

      import_remote_asset(remote_asset, barcode, @import_step) if remote_asset
    end

    def import_barcodes(barcodes)
      @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Import'), state: 'running')
      SequencescapeClient.labware(barcode: barcodes).map do |remote_asset|
        import_remote_asset(remote_asset, remote_asset.labware_barcode['human_barcode'], @import_step)
      end
    end

    def create_local_asset(barcode, updates)
      ActiveRecord::Base.transaction do
        Asset.create!(:barcode => barcode).tap do |asset|
          updates.add(asset, 'a', 'Tube')
          updates.add(asset, 'barcodeType', 'Code2D')
          updates.add(asset, 'is', 'Empty')
        end
      end
    end

    # Caution: This method had unexpected side effects. It will:
    # 1) Also find assets by uuid
    # 2) Automatically create an asset if the barcode passed to it is a fluidx format barcode
    def find_or_import_asset_with_barcode(barcode)
      barcode = TokenUtil.human_barcode(barcode) if TokenUtil.machine_barcode?(barcode)
      find_asset_with_barcode(barcode) || import_barcode(barcode)
    end

    # One call
    def update_asset_from_remote_asset(asset, remote_asset, fact_changes)
      fact_changes.replace_remote(asset, 'a', sequencescape_type_for_asset(remote_asset))

      if remote_asset.sync?
        fact_changes.replace_remote(asset, 'pushTo', 'Sequencescape')
        fact_changes.replace_remote(asset, 'purpose', remote_asset.purpose.name) if remote_asset.try(:purpose)
      end

      fact_changes.replace_remote(asset, 'is', 'NotStarted')

      annotate_container(asset, remote_asset, fact_changes)
      annotate_wells(asset, remote_asset, fact_changes)
      annotate_tubes(asset, remote_asset, fact_changes)
      annotate_study_name(asset, remote_asset, fact_changes)

      asset.update_digest_with_remote(remote_asset)
    end

    def annotate_container(asset, remote_asset, fact_changes)
      return unless remote_asset.try(:aliquots)

      remote_asset.aliquots.each do |aliquot|
        fact_changes.replace_remote(asset, 'sample_tube', asset)
        fact_changes.replace_remote(asset, 'sanger_sample_id', TokenUtil.quote_if_uuid(aliquot&.sample&.sanger_sample_id))
        fact_changes.replace_remote(asset, 'sample_uuid', TokenUtil.quote(aliquot&.sample&.uuid), literal: true)
        fact_changes.replace_remote(asset, 'sanger_sample_name', TokenUtil.quote_if_uuid(aliquot&.sample&.name))
        fact_changes.replace_remote(asset, 'supplier_sample_name', TokenUtil.quote_if_uuid(aliquot&.sample&.sample_metadata&.supplier_name))
        fact_changes.replace_remote(asset, 'sample_common_name', TokenUtil.quote_if_uuid(aliquot&.sample&.sample_metadata&.sample_common_name))
      end
    end

    def annotate_study_name_from_aliquots(asset, remote_asset, fact_changes)
      return unless remote_asset.try(:aliquots)

      return unless ((remote_asset.aliquots.count == 1) && (remote_asset.aliquots.first.sample))

      fact_changes.replace_remote(asset, 'study_name', remote_asset.aliquots.first.study.name)
      fact_changes.replace_remote(asset, 'study_uuid', TokenUtil.quote(remote_asset.aliquots.first.study.uuid), literal: true)
    end

    def annotate_study_name(asset, remote_asset, fact_changes)
      if remote_asset.try(:wells)
        remote_asset.wells.detect do |w|
          annotate_study_name_from_aliquots(asset, w, fact_changes)
        end
      elsif remote_asset.try(:racked_tubes)
        remote_asset.racked_tubes.detect do |rt|
          annotate_study_name_from_aliquots(asset, rt.tube, fact_changes)
        end
      else
        annotate_study_name_from_aliquots(asset, remote_asset, fact_changes)
      end
    end

    def annotate_wells(asset, remote_asset, fact_changes)
      return unless remote_asset.try(:wells)

      remote_asset.wells.each do |well|
        local_well = Asset.find_or_create_by!(uuid: well.uuid)

        fact_changes.replace_remote(asset, 'contains', local_well)

        # Updated wells will also mean that the plate is out of date, so we'll set it in the asset
        fact_changes.replace_remote(local_well, 'a', 'Well')
        fact_changes.replace_remote(local_well, 'location', well.position['name'])
        fact_changes.replace_remote(local_well, 'parent', asset)

        if (well.try(:aliquots)&.first&.sample&.sample_metadata&.supplier_name)
          annotate_container(local_well, well, fact_changes)
        end
      end
    end

    def annotate_tubes(asset, remote_asset, fact_changes)
      return unless remote_asset.try(:racked_tubes)

      remote_asset.racked_tubes.each do |racked_tube|
        remote_tube = racked_tube.tube
        local_tube = Asset.find_or_create_by!(uuid: remote_tube.uuid)
        local_tube.update!(barcode: remote_tube.labware_barcode['human_barcode'])

        fact_changes.replace_remote(asset, 'contains', local_tube)

        # Updated tubes will also mean that the plate is out of date, so we'll set it in the asset
        fact_changes.replace_remote(local_tube, 'a', 'SampleTube')
        fact_changes.replace_remote(local_tube, 'location', racked_tube.coordinate)
        fact_changes.replace_remote(local_tube, 'parent', asset)

        if (remote_tube.try(:aliquots)&.first&.sample&.sample_metadata&.supplier_name)
          annotate_container(local_tube, remote_tube, fact_changes)
        end
      end
    end

    def sequencescape_type_for_asset(remote_asset)
      return nil unless remote_asset.type

      type = remote_asset.type.singularize.classify
      return 'SampleTube' if type == 'Tube'

      return type
    end

    # Finds Assets with the provided barcodes in the local Assets table, and
    # looks up any missing barcodes in Sequencescape, importing the assets if
    # required. If a barcode is missing both locally, and in Sequencescape, it
    # will not be included in the response. It is up to the caller to determine
    # how to handle this. @note The behaviour differs from the singular
    # #find_or_import_asset_with_barcode in that it will not also attempt to
    # lookup by uuid, and will not automatically register fluidx barcodes
    def find_or_import_assets_with_barcodes(barcodes, includes: :facts)
      local_assets = Asset.includes(includes).where(barcode: barcodes).to_a
      remote_assets = import_barcodes(barcodes - local_assets.pluck(:barcode))
      local_assets + remote_assets
    end

    private

    def import_remote_asset(remote_asset, barcode, import_step)
      Asset.create!(barcode: barcode, uuid: remote_asset.uuid).tap do |asset|
        FactChanges.new.tap do |updates|
          updates.replace_remote(asset, 'a', sequencescape_type_for_asset(remote_asset))
          updates.replace_remote(asset, 'remoteAsset', remote_asset.uuid)
        end.apply(import_step)
        asset.refresh_from_remote(remote_asset: remote_asset)
        asset.update_compatible_activity_type
      end
    end

    def find_asset_with_barcode(barcode)
      asset = Asset.find_by_barcode(barcode) || Asset.find_by_uuid(barcode)

      updates = FactChanges.new

      if asset.nil? && TokenUtil.is_valid_fluidx_barcode?(barcode)
        asset = import_barcode(barcode) || Asset.create_local_asset(barcode, updates)
      end

      asset&.refresh(updates)
      asset
    end
  end
end
