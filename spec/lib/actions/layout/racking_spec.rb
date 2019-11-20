require 'rails_helper'
require 'actions/layout_processor'

RSpec.describe 'Actions::Layout::Racking' do
  let(:layout_processor) { Actions::LayoutProcessor.new({}) }
  let(:positions) { TokenUtil.generate_positions(('A'..'F').to_a, (1..12).to_a) }

  describe '#changes_for_put_tube_into_rack_position' do
    let(:rack) { create :tube_rack }
    let(:position) { 'A01'}
    let(:tube) { create :tube }
    it 'returns all changes to put the tube in the rack' do
      updates = layout_processor.changes_for_put_tube_into_rack_position(tube, rack, position)
      expect(updates.to_h[:add_facts]).to include(
        [tube.uuid, 'location', position],
        [tube.uuid, 'parent', rack.uuid],
        [rack.uuid, 'contains', tube.uuid]
      )
    end
  end

  describe '#changes_for_rack_tubes' do
    let(:tube1) {create :tube }
    let(:tube2) {create :tube }
    let(:rack) { create :tube_rack }
    let(:layout) {
      [{location: 'A01', asset: nil}, {location: 'B01', asset: tube1}, {location: 'C01', asset: tube2}]
    }
    it 'puts the tubes in the rack following the layout' do
      updates = layout_processor.changes_for_rack_tubes(layout, rack)
      expect(updates.to_h[:add_facts]).to include(
        [rack.uuid, 'contains', tube1.uuid],
        [rack.uuid, 'contains', tube2.uuid],
        [tube1.uuid, 'location', 'B01'],
        [tube1.uuid, 'parent', rack.uuid],
        [tube2.uuid, 'location', 'C01'],
        [tube2.uuid, 'parent', rack.uuid]
      )
    end
    it 'also adds inherited fields' do
      tube2.facts << create(:fact, predicate: 'study_name', object: 'STDY1', literal: true)
      updates = layout_processor.changes_for_rack_tubes(layout, rack)
      expect(updates.to_h[:add_facts]).to include([rack.uuid, 'study_name', 'STDY1'])
    end
  end

  describe '#changes_for_rack_when_racking_tubes' do
    let(:rack) { create :tube_rack }
    let(:tube1) { create(:tube, :inside_rack, location: "A01", parent: rack) }
    let(:tube2) { create(:tube, :inside_rack, location: "B01", parent: rack) }
    let(:tubes) {[tube1, tube2]}

    it 'transfers the relevant properties from the tubes into the racks' do
      Actions::LayoutProcessor::TUBE_TO_RACK_TRANSFERRABLE_PROPERTIES.push('country')
      tube1.facts << create(:fact, predicate: 'country', object: 'Spain', literal: true)
      tube2.facts << create(:fact, predicate: 'country', object: 'Portugal', literal: true)

      updates = layout_processor.changes_for_rack_when_racking_tubes(rack, tubes)
      expect(updates.to_h[:add_facts]).to eq(
        [[rack.uuid, 'country', 'Spain'],
        [rack.uuid, 'country', 'Portugal']]
      )
    end
    it 'does not transfer non-relevant properties from tubes to the rack' do
      property = SecureRandom.uuid
      tube2.facts << create(:fact, predicate: property, object: 'Orange', literal: true)
      updates = layout_processor.changes_for_rack_when_racking_tubes(rack, tubes)
      expect(updates.to_h[:add_facts]).to be_nil
    end
  end
end
