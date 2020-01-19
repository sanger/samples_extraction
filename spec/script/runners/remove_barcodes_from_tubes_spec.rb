require 'rails_helper'

require Rails.root.to_s+'/script/runners/remove_barcodes_from_tubes'

RSpec.describe 'RemoveBarcodesFromTubes' do
  let!(:num_wells) { 3 }

  let(:activity) { create :activity }
  let(:step) { create :step, activity: activity, state: Step::STATE_RUNNING }

  let(:barcodes) {
    num_wells.times.map{|i| "FR00#{i}"}
  }
  let(:padded_locations) {
    num_wells.times.map{|i| "A0#{i}"}
  }

  let(:locations) {
    num_wells.times.map{|i| "A#{i}"}
  }
  let(:wells_for_rack) {
    num_wells.times.map do |i|
      asset = create(:asset, barcode: barcodes[i])
      asset.facts << create(:fact, predicate: 'a', object: 'Tube')
      asset.facts << create(:fact, predicate: 'location', object: padded_locations[i])
      asset
    end
  }
  let(:tube_rack) {
    asset = create :asset
    asset.facts << create(:fact, predicate: 'a', object: 'TubeRack')
    asset.facts << wells_for_rack.map{|a| create(:fact, predicate: 'contains', object_asset: a)}
    asset
  }

  context 'when run with a rack with tubes' do
    it 'removes the barcodes from the tubes' do
      group = create(:asset_group, assets: [tube_rack])
      updates = RemoveBarcodesFromTubes.new(asset_group: group).process
      changes = updates.to_h

      expect(changes[:remove_facts].select{|t| t[1] == 'barcode'}.count).to eq(num_wells)

      wells_for_rack.each_with_index do |w, pos|
        expect(changes[:remove_facts]).to include(
          [w.uuid, 'barcode', barcodes[pos]])
      end
    end
  end
end
