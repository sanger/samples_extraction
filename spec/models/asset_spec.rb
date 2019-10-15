require 'rails_helper'
RSpec.describe Asset do
  context '#has_wells?' do
    it 'returns true when it is a plate with wells' do
      plate = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Plate')
      well = create(:asset)
      plate.facts << create(:fact, predicate: 'contains', object_asset: well)
      expect(plate.has_wells?).to eq(true)
    end
    it 'returns false when it is an empty plate' do
      plate = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Plate')
      well = create(:asset)
      expect(plate.has_wells?).to eq(false)
    end
    it 'returns false when it is something else' do
      plate = create(:asset)
      something_else = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Bottle')
      well = create(:asset)
      plate.facts << create(:fact, predicate: 'contains', object_asset: well)
      expect(plate.has_wells?).to eq(false)
      something_else = create(:asset)
      expect(something_else.has_wells?).to eq(false)
    end
  end
end
