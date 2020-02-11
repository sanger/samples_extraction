require 'rails_helper'
require 'message_processors/asset_group_message_processor'

RSpec.describe MessageProcessors::AssetGroupMessageProcessor do
  context 'an instance of AssetGroupMessageProcessor' do
    let(:channel) { double('channel')}
    let(:barcodes) { 2.times.map{create(:tube, :with_barcode) }.map(&:barcode) }
    let(:asset_group) { create(:asset_group)}
    let(:good_message) { { asset_group: { id: asset_group.id, assets: barcodes }}.as_json}
    let(:bad_message) { { asset_group: {} } }
    let(:instance) { MessageProcessors::AssetGroupMessageProcessor.new(channel: channel)}

    before do
      allow(SequencescapeClient).to receive(:find_by_uuid).and_return(nil)
      allow(SequencescapeClient).to receive(:get_remote_asset).and_return(nil)
    end
    context '#interested_in?' do
      it 'returns true if is an asset_group message' do
        expect(instance.interested_in?(good_message)).to be_truthy
      end
      it 'returns false if is not an asset_group message' do
        expect(instance.interested_in?(bad_message)).to be_falsy
      end
    end
    context '#process' do
      context 'when receiving a new group of barcodes inside an asset group' do
        let(:added) { 2.times.map{create(:tube, :with_barcode) } }
        let(:removed) { 2.times.map{create(:tube, :with_barcode) } }
        let(:kept) { 2.times.map{create(:tube, :with_barcode) } }
        let(:new_list) {[kept, added].flatten}
        let(:previous_list) { [removed, kept].flatten}
        let(:assets) { new_list }
        let(:asset_group) {create(:asset_group, assets: previous_list) }
        let(:barcodes) { assets.map(&:barcode) }

        it 'updates the contents of the group' do
          expect{instance.process(good_message)}.to change{
            asset_group.assets.reload
            asset_group.assets.map(&:barcode)
          }.from(previous_list.map(&:barcode)).to(new_list.map(&:barcode))
        end
      end
    end
  end
end
