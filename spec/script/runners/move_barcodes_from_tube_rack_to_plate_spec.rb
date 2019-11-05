require 'rails_helper'

require Rails.root.to_s+'/script/runners/move_barcodes_from_tube_rack_to_plate'

RSpec.describe 'MoveBarcodesFromTubeRackToPlate' do
  NUM_WELLS = 3

  let(:barcodes) {
    NUM_WELLS.times.map{|i| "FR00#{i}"}
  }
  let(:locations) {
    NUM_WELLS.times.map{|i| "A#{i}"}
  }
  let(:wells_for_rack) {
    NUM_WELLS.times.map do |i|
      asset = create(:asset, barcode: barcodes[i])
      asset.facts << create(:fact, predicate: 'a', object: 'Tube')
      asset.facts << create(:fact, predicate: 'location', object: locations[i])
      asset
    end
  }
  let(:wells_for_plate) {
    NUM_WELLS.times.map do |i|
      asset = create(:asset)
      asset.facts << create(:fact, predicate: 'a', object: 'Well')
      asset.facts << create(:fact, predicate: 'location', object: locations[i])
      asset
    end
  }
  let(:tube_rack) {
    asset = create :asset
    asset.facts << create(:fact, predicate: 'a', object: 'TubeRack')
    asset.facts << wells_for_rack.map{|a| create(:fact, predicate: 'contains', object_asset: a)}
    asset
  }
  let(:plate) {
    asset = create :asset
    asset.facts << create(:fact, predicate: 'a', object: 'Plate')
    asset.facts << wells_for_plate.map{|a| create(:fact, predicate: 'contains', object_asset: a)}
    asset
  }

  context 'when run with a tube rack and a plate' do
    it 'adds the barcodes of the tube rack into the wells of the plate' do
      group = create(:asset_group, assets: [plate, tube_rack])
      changes = MoveBarcodesFromTubeRackToPlate.new(asset_group: group).process.to_h

      expect(changes[:add_facts].select{|t| t[1] == 'barcode'}.count).to eq(NUM_WELLS)

      wells_for_plate.each_with_index do |w, pos|
        expect(changes[:add_facts]).to include(
          [w.uuid, 'barcode', barcodes[pos]])
      end
    end
    it 'removes the barcodes from the tubes of the tube rack' do
      group = create(:asset_group, assets: [plate, tube_rack])
      changes = MoveBarcodesFromTubeRackToPlate.new(asset_group: group).process.to_h

      expect(changes[:remove_facts].select{|t| t[1] == 'barcode'}.count).to eq(NUM_WELLS)

      wells_for_rack.each_with_index do |w, pos|
        expect(changes[:remove_facts]).to include(
          [w.uuid, 'barcode', barcodes[pos]])
      end
    end

  end
end
