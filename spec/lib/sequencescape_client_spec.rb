require 'rails_helper'
require 'sequencescape_client'
require 'remote_assets_helper'

RSpec.describe 'SequencescapeClient' do
  include RemoteAssetsHelper
  context '#get_remote_asset' do
    context 'when asked for a list of asset uuids' do

      let(:assets) {
        [
          build_remote_tube(barcode_objs[0]),
          build_remote_plate(barcode_objs[1]),
          build_remote_tube(barcode_objs[2]),
          build_remote_plate(barcode_objs[3])
        ]
      }
      let(:barcode_objs) {
        4.times.map { {labware_barcode: {'human_barcode' => generate(:barcode)}} }
      }
      let(:barcodes) {
        assets.map{|a| a.labware_barcode['human_barcode']}
      }
      let(:params) { {barcode: barcodes}}
      before do
        allow(SequencescapeClientV2::Plate).to receive(:where).with(params).and_return([assets[1], assets[3]])
        allow(SequencescapeClientV2::Tube).to receive(:where).with(params).and_return([assets[0], assets[2]])
      end

      it 'returns the matched elements in response sorted in the same order of the query' do
        expect(SequencescapeClient.get_remote_asset(barcodes)).to eq(assets)
      end
    end
  end

  context '#find_by_uuid' do
    context 'when asked for a list of asset uuids' do
      let(:assets) {
        [create(:tube), create(:plate), create(:tube), create(:well)]
      }
      let(:uuids) { assets.map(&:uuid)}
      let(:params) { {uuid: uuids}}
      before do
        allow(SequencescapeClientV2::Plate).to receive(:where).with(params).and_return([assets[1]])
        allow(SequencescapeClientV2::Tube).to receive(:where).with(params).and_return([assets[0], assets[2]])
        allow(SequencescapeClientV2::Well).to receive(:where).with(params).and_return([assets[3]])
      end

      it 'returns the matched elements in response sorted in the same order of the query' do
        expect(SequencescapeClient.find_by_uuid(uuids)).to eq(assets)
      end
    end
  end

  context '#find_by' do
    let(:assets) { 3.times.map{ create(:asset) }}
    let(:uuids) { assets.map(&:uuid) }
    let(:params) { { uuid: uuids } }
    let(:tube_resource) { double('tube_resource')}
    let(:plate_resource) { double('plate_resource')}
    let(:well_resource) { double('well_resource')}
    let(:resources) { [plate_resource, tube_resource, well_resource]}

    before do
      allow(tube_resource).to receive(:where).with(params).and_return(assets)
      allow(plate_resource).to receive(:where)
      allow(well_resource).to receive(:where)
    end

    it 'performs one request for each asset to match all possible elements' do
      expect(SequencescapeClient.find_by(resources, params)).to eq(assets)
      expect(tube_resource).to have_received(:where).with(params)
      expect(plate_resource).to have_received(:where).with(params)
      expect(well_resource).to have_received(:where).with(params)
    end
  end

  context '#find_first' do
    let(:asset) { create :tube }
    let(:params) { { uuid: asset.uuid } }

    let(:tube_resource) { double('tube_resource')}
    let(:plate_resource) { double('plate_resource')}
    let(:well_resource) { double('well_resource')}
    let(:resources) { [plate_resource, tube_resource, well_resource]}

    before do
      allow(plate_resource).to receive(:where)
      allow(tube_resource).to receive(:where).with(params).and_return([asset])
      allow(well_resource).to receive(:where)
    end

    it 'stops performing subsequente requests when the element is found' do
      expect(SequencescapeClient.find_first(resources, params)).to eq(asset)
      expect(plate_resource).to have_received(:where).with(params)
      expect(tube_resource).to have_received(:where).with(params)
      expect(well_resource).not_to have_received(:where).with(params)
    end
  end

end
