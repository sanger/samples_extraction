require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  def create_well(location, sample, aliquot)
    well = create(:asset)
    well.facts << create(:fact, predicate: 'location', object: location)
    well.facts << create(:fact, predicate: 'supplier_sample_name', object: sample)
    well.facts << create(:fact, predicate: 'aliquotType', object: aliquot)
    well.facts << create(:fact, predicate: 'a', object: 'Well')
    well
  end

  context '#data_asset_display_for_plate' do
    it 'generates the right output for wells with samples' do
      well1 = create_well('A1', 'sample1', 'DNA')
      well2 = create_well('B1', 'sample2', 'RNA')
      well3 = create_well('C1', 'sample3', 'bubidibu')
      well4 = create_well('D1', 'sample4', nil)

      facts = [
        create(:fact, predicate: 'contains', object_asset: well1),
        create(:fact, predicate: 'contains', object_asset: well2),
        create(:fact, predicate: 'contains', object_asset: well3),
        create(:fact, predicate: 'contains', object_asset: well4)
      ]

      asset = create(:asset, facts: facts)

      obj = {
        "A1" => {cssClass: 'DNA'},
        "B1" => {cssClass: 'RNA'},
        "C1" => {cssClass: 'bubidibu'},
        "D1" => {cssClass: helper.unknown_aliquot_type},
      }
      val = helper.data_asset_display_for_plate(asset.facts)
      expect(val.keys).to eq(obj.keys)
      expect(val.values.pluck(:cssClass)).to eq(obj.values.pluck(:cssClass))
    end
    it 'does not filter out wells with location and barcode' do
      well5 = create_well('E1', nil, 'DNA')
      well6 = create_well(nil, 'sample6', 'DNA')

      well5.update_attributes(barcode: 'S1234')

      facts = [
        create(:fact, predicate: 'contains', object_asset: well5),
        create(:fact, predicate: 'contains', object_asset: well6)
      ]
      asset = create(:asset, facts: facts)

      obj = {
        "E1" => {cssClass: 'DNA'},
      }

      val = helper.data_asset_display_for_plate(asset.facts)

      expect(val.keys).to eq(obj.keys)
      expect(val.values.pluck(:cssClass)).to eq(obj.values.pluck(:cssClass))
    end
    it 'filters out wells without samples or location' do
      well5 = create_well('E1', nil, 'DNA')
      well6 = create_well(nil, 'sample6', 'DNA')

      facts = [
        create(:fact, predicate: 'contains', object_asset: well5),
        create(:fact, predicate: 'contains', object_asset: well6)
      ]
      asset = create(:asset, facts: facts)

      val = helper.data_asset_display_for_plate(asset.facts)
      expect(val).to eq({})
    end
  end
end
