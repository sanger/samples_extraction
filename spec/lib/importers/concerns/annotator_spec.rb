require 'rails_helper'
require 'remote_assets_helper'
require 'importers/concerns/annotator'

RSpec.describe 'Importers::Concerns::Annotator' do
  include RemoteAssetsHelper
  let(:plate) { create :plate }
  let(:remote_asset) { build_remote_plate }
  let(:barcodes) { ['1', '2']}
  let(:instance) { Importers::Concerns::Annotator.new(plate, remote_asset) }

  context '#update_asset_from_remote_asset' do
    let(:remote_asset) { build_remote_plate }


    it 'updates the information from the remote asset into the local asset' do
      updates = instance.update_asset_from_remote_asset
      expect(updates.to_h[:add_facts].select{|t| t[1]=='a' && t[2]=='Well'}.length).not_to eq(0)
    end
  end

  context '#update_digest_with_remote' do
    it 'updates the digest with the remote asset provided' do
      digest = instance.digest_for_remote_asset
      updates = instance.update_digest_with_remote
      expect(updates.to_h[:add_facts].select{|t| t[1]=='remote_digest'}).to eq([[plate.uuid, 'remote_digest', digest]])
    end
  end

  context '#sequencescape_type_for_asset' do
    it 'returns the class from the Sequencescape remote asset' do
      expect(instance.sequencescape_type_for_asset).to eq('Plate')
    end
  end

  context '#is_not_a_sample_tube?' do
    let(:remote_tube) { build_remote_tube }
    it 'returns false if the element is a sample tube' do
      instance = Importers::Concerns::Annotator.new(plate, remote_tube)
      expect(instance.is_not_a_sample_tube?).to be_falsy
    end
    it 'returns true if the element is not a sample Tube' do
      instance = Importers::Concerns::Annotator.new(plate, remote_asset)
      expect(instance.is_not_a_sample_tube?).to be_truthy
    end
  end

  context '#annotate_wells' do
    let(:plate) { create :plate }

    it 'replicates wells information from the remote asset into the local plate' do
      updates = instance.annotate_wells(plate, remote_asset)
      expect(updates.to_h[:create_assets]).not_to be_nil
      expect(updates.to_h[:create_assets]).to eq(remote_asset.wells.map(&:uuid))
      wells_defs = updates.to_h[:add_facts].select{|t| t[1]=='a' && t[2] == 'Well'}
      expect(wells_defs.count).to eq(remote_asset.wells.count)
    end

    it 'does not create new wells if they already exist in local' do
      remote_asset.wells.each do |w|
        create :asset, uuid: w.uuid
      end
      updates = instance.annotate_wells(plate, remote_asset)
      expect(updates.to_h[:create_assets]).to be_nil
    end
  end

  context '#annotate_study_name' do
    context 'when it is a plate' do
      let(:plate) { create :plate }
      it 'calls annotate_study_name_from_aliquots for each well' do
        allow(instance).to receive(:annotate_study_name_from_aliquots)
        instance.annotate_study_name(plate, remote_asset)
        expect(instance).to have_received(:annotate_study_name_from_aliquots).exactly(remote_asset.wells.count)
      end
    end
    context 'when it is not a plate' do
      let(:remote_asset) { build_remote_tube }
      let(:tube) { create :tube }
      it 'calls annotate_study_name_from_aliquots once' do
        allow(instance).to receive(:annotate_study_name_from_aliquots)
        instance.annotate_study_name(tube, remote_asset)
        expect(instance).to have_received(:annotate_study_name_from_aliquots).once
      end
    end
  end

  context '#annotate_study_name_from_aliquots' do
    let(:remote_asset) { build_remote_tube }
    let(:tube) { create :tube }

    it 'annotates the study information in the asset' do
      updates = instance.annotate_study_name_from_aliquots(tube, remote_asset)
      expect(updates.to_h[:add_facts].select{|t| t[1]=='study_uuid'}.length).not_to eq(0)
    end
  end

  context '#annotate_container' do
    let(:remote_asset) { build_remote_tube }
    let(:tube) { create :tube }

    it 'annotates the container information in the asset' do
      updates = instance.annotate_container(tube, remote_asset)
      expect(updates.to_h[:add_facts].select{|t| t[1]=='sample_uuid'}.length).not_to eq(0)
    end
  end

end
