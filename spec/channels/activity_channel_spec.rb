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

      before { allow(AssetGroup).to receive(:find).with(group.id).and_return(group) }

      it 'processes asset group' do
        expect(instance).to receive(:process_asset_group)
        instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
      end

      context 'when receiving uuids' do
        let!(:tubes) { [create(:asset, uuid: assets[0]), create(:asset, uuid: assets[1])] }
        let(:assets) { [SecureRandom.uuid, SecureRandom.uuid] }
        it 'imports uuids' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with([]).and_return([])
          expect(group).to receive(:update_with_assets).with(tubes)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end

      context 'when receiving human barcodes' do
        let(:tubes) { [create(:asset, barcode: 'human1'), create(:asset, barcode: 'human2')] }
        let(:assets) { tubes.map(&:barcode) }

        it 'imports human barcodes' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(assets).and_return(tubes)
          expect(group).to receive(:update_with_assets).with(tubes)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end

      context 'when receiving machine barcodes' do
        let!(:tubes) { [create(:asset, barcode: 'NT1767662F'), create(:asset, barcode: 'NT1767663G')] }
        let(:human_barcodes) { tubes.map(&:barcode) }
        let(:assets) { %w[3981767662700 3981767663714] }

        it 'imports machines barcodes' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(tubes)
          expect(group).to receive(:update_with_assets).with(tubes)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end

      context 'when receiving all different types of inputs' do
        let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
        let(:uuid_assets) { [create(:asset, uuid: uuids[0]), create(:asset, uuid: uuids[1])] }
        let(:human_assets) do
          [
            create(:asset, barcode: 'human1'),
            create(:asset, barcode: 'human2'),
            create(:asset, barcode: 'NT1767662F'),
            create(:asset, barcode: 'NT1767663G')
          ]
        end
        let(:human_barcodes) { %w[human1 human2 NT1767662F NT1767663G] }
        let(:assets) { ['human1', 'human2', uuids[0], uuids[1], '3981767662700', '3981767663714'] }
        let(:tubes) do
          [human_assets[0], human_assets[1], uuid_assets[0], uuid_assets[1], human_assets[2], human_assets[3]]
        end

        it 'imports all inputs right' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(human_assets)
          expect(group).to receive(:update_with_assets).with(tubes)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end
    end
  end
  context 'ActivityChannel::BarcodeInputResolver' do
    context 'with uuids' do
      let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
      let!(:assets) { [create(:asset, uuid: uuids[0]), create(:asset, uuid: uuids[1])] }
      it 'can resolve uuids' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with([]).and_return([])
        resolver = ActivityChannel::BarcodeInputResolver.new
        uuids.each { |uuid| resolver.add_input(uuid) }
        expect(resolver.resolved_assets.assets).to eq(assets)
      end
    end
    context 'with human barcodes' do
      let(:assets) { [create(:asset, barcode: 'human1'), create(:asset, barcode: 'human2')] }
      let(:human_barcodes) { assets.map(&:barcode) }
      it 'can resolve uuids' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(assets)
        resolver = ActivityChannel::BarcodeInputResolver.new
        human_barcodes.each { |barcode| resolver.add_input(barcode) }
        expect(resolver.resolved_assets.assets).to eq(assets)
      end
    end
    context 'with machine barcodes' do
      let!(:assets) { [create(:asset, barcode: 'NT1767662F'), create(:asset, barcode: 'NT1767663G')] }
      let(:human_barcodes) { assets.map(&:barcode) }
      let(:machine_barcodes) { %w[3981767662700 3981767663714] }

      it 'can resolve uuids' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(assets)
        resolver = ActivityChannel::BarcodeInputResolver.new
        machine_barcodes.each { |barcode| resolver.add_input(barcode) }
        expect(resolver.resolved_assets.assets).to eq(assets)
      end
    end
    context 'with mixed content' do
      let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }

      let!(:assets) do
        [human_assets[0], uuid_assets[1], human_assets[1], human_assets[2], human_assets[3], uuid_assets[0]]
      end
      let(:uuid_assets) { [create(:asset, uuid: uuids[0]), create(:asset, uuid: uuids[1])] }
      let(:inputs) { ['human1', uuids[1], '3981767663714', 'human2', '3981767662700', uuids[0]] }
      let!(:human_assets) do
        [
          create(:asset, barcode: 'human1'),
          create(:asset, barcode: 'NT1767663G'),
          create(:asset, barcode: 'human2'),
          create(:asset, barcode: 'NT1767662F')
        ]
      end
      let!(:human_barcodes) { human_assets.map(&:barcode) }
      let(:machine_barcodes) { %w[3981767663714 3981767662700] }

      it 'keeps the order of the input in the resolved assets' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(human_assets)
        resolver = ActivityChannel::BarcodeInputResolver.new
        inputs.each { |barcode| resolver.add_input(barcode) }
        expect(resolver.resolved_assets.assets).to eq(assets)
      end

      it 'can handle missing barcodes' do
        human_assets[2] = nil

        expect(Asset).to receive(:find_or_import_assets_with_barcodes)
        expect(Asset).to receive(:where).with(uuid: [uuids[1], uuids[0]]).and_return(uuid_assets)
        expect(Asset).to receive(:where).with(barcode: human_barcodes).and_return(human_assets)

        resolver = ActivityChannel::BarcodeInputResolver.new
        inputs.each { |barcode| resolver.add_input(barcode) }
        obtained_assets = [assets[0], assets[1], assets[2], assets[4], assets[5]]

        missing_inputs = ['human2']

        expect(resolver.resolved_assets.assets).to eq(obtained_assets)
        expect(resolver.resolved_assets.missing_inputs).to eq(missing_inputs)
      end
    end
  end
end
