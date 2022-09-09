# frozen_string_literal: true
require 'rails_helper'

class MyTest < ActivityChannel
  # rubocop:disable Lint/MissingSuper
  def initialize
    nil
  end
  # rubocop:enable Lint/MissingSuper
end


RSpec.describe ActivityChannel, type: :channel do
  context '#receive' do

    context 'when receiving a asset group' do
      let(:instance) { MyTest.new }
      let(:group) { create :asset_group }
      let(:assets) { [] }

      it 'processes asset group' do
        expect(instance).to receive(:process_asset_group)
        instance.receive({'asset_group' => {id: group.id, assets: assets}})
      end
      
      context 'when receiving uuids' do
        let!(:tubes) do [
          create(:asset, uuid: assets[0]),
          create(:asset, uuid: assets[1])
        ] end
        let(:assets) { [SecureRandom.uuid, SecureRandom.uuid] }
        it 'imports uuids' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with([]).and_return([])
          instance.receive({'asset_group' => {id: group.id, assets: assets}})
        end
      end

      context 'when receiving human barcodes' do
        let(:tubes) do [
          create(:asset, barcode: 'human1'),
          create(:asset, barcode: 'human2')
        ] end
        let(:assets) { tubes.map(&:barcode) }

        it 'imports human barcodes' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(assets).and_return(tubes)
          instance.receive({'asset_group' => {id: group.id, assets: assets}})
        end
      end

      context 'when receiving machine barcodes' do
        let(:tubes) do [
          create(:asset, barcode: 'NT1767662F'),
          create(:asset, barcode: 'NT1767663G')
        ] end
        let(:human_barcodes) { tubes.map(&:barcode) }
        let(:assets) { ['3981767662700','3981767663714'] }
        
        it 'imports machines barcodes' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(tubes)
          instance.receive({'asset_group' => {id: group.id, assets: assets}})
        end
      end

      context 'when receiving all different types of inputs' do
        let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid]}
        let(:uuid_assets) do 
          [
            create(:asset, uuid: uuids[0]),
            create(:asset, uuid: uuids[1]),
          ] 
        end
        let(:human_assets) do
          [            
            create(:asset, barcode: 'human1'),
            create(:asset, barcode: 'human2'),
            create(:asset, barcode: 'NT1767662F'),
            create(:asset, barcode: 'NT1767663G')
          ]
        end
        let(:human_barcodes) { ['human1', 'human2', 'NT1767662F', 'NT1767663G'] }
        let(:assets) do [
          'human1', 'human2',
          uuids[0], uuids[1],
          '3981767662700','3981767663714'
          ] 
        end
        let(:tubes) do 
          [human_assets[0], human_assets[1], uuid_assets[0], uuid_assets[1], human_assets[2], human_assets[3]]
        end
        
        it 'imports all inputs right' do
          allow(AssetGroup).to receive(:find).with(group.id).and_return(group)
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(
            human_assets
          )
          expect(group).to receive(:update_with_assets).with(tubes)
          instance.receive({'asset_group' => {id: group.id, assets: assets}})
        end
      end
    end
  end
end