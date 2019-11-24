require 'rails_helper'
require 'remote_assets_helper'
require 'importers/barcodes_importer'
require 'fact_changes'

RSpec.describe Importers::BarcodesImporter do
  include RemoteAssetsHelper
  let(:barcodes) { 4.times.map{generate(:barcode)}}
  let(:remote_assets) { barcodes.map{|barcode| build_remote_tube(barcode: barcode)}}

  before do
    allow(SequencescapeClient).to receive(:get_remote_asset).with(barcodes).and_return(remote_assets)
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
      expect(instance).to have_received(:refresh_assets) do |args|
        expect(args.to_a).to eq([asset1])
      end
    end
    it 'imports all barcodes not present in database' do
      asset1 = create(:asset, barcode: generate(:barcode))
      barcodes_and_local = [barcodes, asset1.barcode].flatten
      instance = Importers::BarcodesImporter.new(barcodes_and_local)
      allow(instance).to receive(:import_barcodes)
      instance.process
      expect(instance).to have_received(:import_barcodes).with(barcodes)
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
end
