# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Printables::Group do
  context '#classify_for_printing' do
    context 'when all asset are for the same printer and template' do
      let!(:template1) do
        create(:label_template, name: 'se_ean13_96tube', template_type: 'Tube', external_id: 1)
      end
      let(:props1) do
        [
          create(:fact, predicate: 'a', object: 'Tube')
        ]
      end
      let(:asset1) { create(:asset, facts: props1) }
      let(:asset2) { create(:asset, facts: props1) }
      let(:assets) { [asset1, asset2] }
      let(:group) { create :asset_group, assets: assets }
      let(:config) { { 'Tube' => 'printer1', 'Plate' => 'printer2' } }
      let!(:printer1) { create :printer, name: 'printer1' }
      let!(:printer2) { create :printer, name: 'printer2' }

      it 'classifies all assets to use the right printer' do
        expect(group.classify_for_printing(config)).to eq(
          {
            ['printer1', template1.external_id] => [asset1, asset2]
          }
        )
      end
    end
    context 'when each asset is for a different template and printer' do
      let!(:template1) do
        create(:label_template, name: 'se_ean13_96tube', template_type: 'Tube', external_id: 1)
      end
      let!(:template2) do
        create(:label_template, name: 'se_ean13_96plate', template_type: 'Plate', external_id: 2)
      end
      let(:props1) do
        [
          create(:fact, predicate: 'a', object: 'Tube')
        ]
      end
      let(:props2) do
        [
          create(:fact, predicate: 'a', object: 'Plate')
        ]
      end
      let(:asset1) { create(:asset, facts: props1) }
      let(:asset2) { create(:asset, facts: props2) }
      let(:assets) { [asset1, asset2] }
      let(:group) { create :asset_group, assets: assets }
      let(:config) { { 'Tube' => 'printer1', 'Plate' => 'printer2' } }
      let(:printer1) { create :printer, name: 'printer1' }
      let(:printer2) { create :printer, name: 'printer2' }

      it 'classifies all assets to use the right printer' do
        expect(group.classify_for_printing(config)).to eq(
          {
            ['printer1', template1.external_id] => [asset1],
            ['printer2', template2.external_id] => [asset2]
          }
        )
      end
    end

    context 'when there is no template to print the asset' do
      let!(:template1) do
        create(:label_template, name: 'se_ean13_96tube', template_type: 'Tube', external_id: 1)
      end
      let!(:template2) do
        create(:label_template, name: 'se_ean13_96plate', template_type: 'DEPRECATED_PLATE', external_id: 2)
      end
      let(:props1) do
        [
          create(:fact, predicate: 'a', object: 'Tube')
        ]
      end
      let(:props2) do
        [
          create(:fact, predicate: 'a', object: 'Plate')
        ]
      end
      let(:asset1) { create(:asset, facts: props1) }
      let(:asset2) { create(:asset, facts: props2) }
      let(:assets) { [asset1, asset2] }
      let(:group) { create :asset_group, assets: assets }
      let(:config) { { 'Tube' => 'printer1', 'Plate' => 'printer2' } }
      let(:printer1) { create :printer, name: 'printer1' }
      let(:printer2) { create :printer, name: 'printer2' }

      it 'raises error' do
        expect { group.classify_for_printing(config) }.to raise_error RuntimeError, "Could not find any label template for type 'Plate'. Please contact LIMS support to fix the problem"
      end
    end

    context 'when there is no printer to print the asset' do
      let!(:template1) do
        create(:label_template, name: 'se_ean13_96tube', template_type: 'Tube', external_id: 1)
      end
      let!(:template2) do
        create(:label_template, name: 'se_ean13_96plate', template_type: 'Plate', external_id: 2)
      end
      let(:props1) do
        [
          create(:fact, predicate: 'a', object: 'Tube')
        ]
      end
      let(:props2) do
        [
          create(:fact, predicate: 'a', object: 'Plate')
        ]
      end
      let(:asset1) { create(:asset, facts: props1) }
      let(:asset2) { create(:asset, facts: props2) }
      let(:assets) { [asset1, asset2] }
      let(:group) { create :asset_group, assets: assets }
      let(:config) { { 'Tube' => 'printer1' } }
      let(:printer1) { create :printer, name: 'printer1' }
      let(:printer2) { create :printer, name: 'printer2' }

      it 'raises error' do
        expect { group.classify_for_printing(config) }.to raise_error RuntimeError, 'There is no defined printer for asset with type Plate'
      end
    end
  end

  context '#print' do
    let!(:template1) do
      create(:label_template, name: 'se_ean13_96tube', template_type: 'Tube', external_id: 1)
    end
    let(:props1) do
      [
        create(:fact, predicate: 'a', object: 'Tube')
      ]
    end
    let(:asset1) { create(:asset, facts: props1, barcode: '1') }
    let(:asset2) { create(:asset, facts: props1, barcode: '2') }
    let(:assets) { [asset1, asset2] }
    let(:group) { create :asset_group, assets: assets }
    let(:config) { { 'Tube' => 'printer1', 'Plate' => 'printer2' } }
    let!(:printer1) { create :printer, name: 'printer1' }
    let!(:printer2) { create :printer, name: 'printer2' }

    let(:saveable_mock) { double('saveable') }

    before do
      allow(Rails.configuration).to receive(:printing_disabled).and_return(false)
    end

    it 'sends the right message to PMB' do
      body_print = assets.filter_map(&:printable_object).reverse

      expect(PMB::PrintJob).to receive(:new).with(
        printer_name: 'printer1',
        label_template_id: 1,
        labels: { body: body_print }
      ).and_return(saveable_mock)
      expect(saveable_mock).to receive(:save)
      group.print(config, 'user1')
    end

    context 'when an asset does not have barcode' do
      let(:asset1) { create(:asset, facts: props1, barcode: nil) }
      it 'does not print it' do
        body_print = [asset2.printable_object]

        expect(PMB::PrintJob).to receive(:new).with(
          printer_name: 'printer1',
          label_template_id: 1,
          labels: { body: body_print }
        ).and_return(saveable_mock)
        expect(saveable_mock).to receive(:save)

        group.print(config, 'user1')
      end
    end
  end
end
