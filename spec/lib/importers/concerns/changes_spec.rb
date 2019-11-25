require 'rails_helper'
require 'remote_assets_helper'
require 'importers/barcodes_importer'

RSpec.describe 'Importers::Concerns::Changes' do
  include RemoteAssetsHelper
  context '#refresh_assets' do
    let(:barcodes) { []}
    let(:instance) { Importers::BarcodesImporter.new(barcodes) }
    let(:uuids) { assets.map(&:uuid) }
    let(:assets) { [ create(:plate), create(:tube), create(:plate), create(:well)]}
    let(:remote_assets) {[build_remote_plate, build_remote_tube, build_remote_plate, build_remote_well('B1')]}

    before do
      assets.zip(remote_assets) do |a, remote|
        allow(remote).to receive(:uuid).and_return(a.uuid)
      end
      allow(SequencescapeClient).to receive(:find_by_uuid).with(assets.map(&:uuid)).and_return(remote_assets)
    end

    it 'refreshes the contents of the assets' do
      updates = instance.refresh_assets(assets)
      expect(updates.to_h[:add_facts].detect{|t|t[1]=='sample_uuid'}).not_to be_nil
      expect(updates.to_h[:add_facts].map{|t| t[0]}.uniq).to include(*uuids)
    end

    context 'when receiving an empty list' do
      it 'does nothing' do
        updates = instance.refresh_assets([])
        expect(updates.to_h).to eq({})
      end
    end
  end

  context '#import_barcodes' do
    let(:instance) { Importers::BarcodesImporter.new(barcodes) }

    let(:remote_assets) {
      [
        build_remote_tube(barcode_objs[0]),
        build_remote_plate(barcode_objs[1]),
        build_remote_tube(barcode_objs[2]),
        build_remote_plate(barcode_objs[3])
      ]
    }
    let(:uuids) { remote_assets.map(&:uuid) }
    let(:barcode_objs) {
      4.times.map { {labware_barcode: {'human_barcode' => generate(:barcode)}} }
    }
    let(:barcodes) {
      remote_assets.map{|a| a.labware_barcode['human_barcode']}
    }

    before do
      allow(SequencescapeClient).to receive(:get_remote_asset).with(barcodes).and_return(remote_assets)
    end

    it 'imports the assets' do
      updates = instance.import_barcodes(barcodes)
      expect(updates.to_h[:add_facts].detect{|t|t[1]=='sample_uuid'}).not_to be_nil
      expect(updates.to_h[:create_assets]).to include(*uuids)
    end

    context 'when receiving an empty list' do
      it 'does nothing' do
        updates = instance.import_barcodes([])
        expect(updates.to_h).to eq({})
      end
    end

  end
end
