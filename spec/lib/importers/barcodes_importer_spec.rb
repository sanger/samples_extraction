require 'rails_helper'
require 'remote_assets_helper'
require 'importers/barcodes_importer'
require 'fact_changes'

RSpec.describe Importers::BarcodesImporter do
  include RemoteAssetsHelper
  let(:barcodes) { 4.times.map{generate(:barcode).to_s}}
  let(:remote_assets) { barcodes.map{|barcode| build_remote_tube(barcode: barcode)}}

  before do
    stub_client_with_assets(SequencescapeClient, remote_assets)
  end

  context '#initialize' do
    it 'loads a list of barcodes' do
      instance = Importers::BarcodesImporter.new(barcodes)
      expect(instance.barcodes).to eq(barcodes)
    end
  end
  context '#process' do
    it 'returns a FactChanges instance' do
      instance = Importers::BarcodesImporter.new(barcodes)
      expect(instance.process.class).to eq(FactChanges)
    end
    it 'refreshes all barcodes that are remote' do
      asset1 = create(:asset, barcode: generate(:barcode), remote_digest: '1234')
      barcodes_and_local = [barcodes, asset1.barcode].flatten
      instance = Importers::BarcodesImporter.new(barcodes_and_local)
      allow(instance).to receive(:refresh_assets)
      instance.process
      expect(instance).to have_received(:refresh_assets).with([asset1])
    end
    it 'imports all barcodes not present in database' do
      asset1 = create(:asset, barcode: generate(:barcode), remote_digest: '1234')
      barcodes_and_local = [barcodes, asset1.barcode].flatten
      instance = Importers::BarcodesImporter.new(barcodes_and_local)
      allow(instance).to receive(:import_barcodes)
      allow(instance).to receive(:refresh_assets)
      instance.process
      expect(instance).to have_received(:import_barcodes).with(barcodes)
      expect(instance).to have_received(:refresh_assets).with([asset1])
    end
  end

  context '#process!' do
    it 'creates the new assets' do
      instance = Importers::BarcodesImporter.new(barcodes)
      expect{
        instance.process!
      }.to change{Asset.count}.from(0).to(4)
    end
  end

  context '#changed_remote?' do
    let(:instance) { Importers::BarcodesImporter.new([barcodes.first]) }
    let(:remote_asset) { remote_assets.first }
    it 'returns false when the asset is not remote' do
      plate = create :plate, remote_digest: nil, uuid: remote_asset.uuid, barcode: barcodes.first
      expect(instance.changed_remote?(plate)).to be_truthy
    end
    it 'detects the change when the stored digest is different from the actual' do
      plate = create :plate, remote_digest: "1234", uuid: remote_asset.uuid, barcode: barcodes.first
      expect(instance.changed_remote?(plate)).to be_truthy
    end
    it 'does not detect change when stored digest is equal to the actual' do
      plate = create :plate, uuid: remote_asset.uuid, barcode: barcodes.first
      digest = Importers::Concerns::Annotator.new(plate, remote_asset).digest_for_remote_asset
      plate.update_attributes(remote_digest: digest)
      expect(instance.changed_remote?(plate)).to be_falsy
    end
  end

end
