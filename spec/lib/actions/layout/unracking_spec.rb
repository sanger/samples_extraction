require 'rails_helper'
require 'actions/layout_processor'

RSpec.describe 'Actions::Layout::Unracking' do
  let(:layout_processor) { Actions::LayoutProcessor.new({}) }
  let(:positions) { TokenUtil.generate_positions(('A'..'F').to_a, (1..12).to_a) }

  describe '#changes_for_tubes_on_unrack' do
    context 'when unracking a list of tubes' do
      let(:tubes_rack_1) {
        3.times.map do |pos|
          create(:tube, :inside_rack, location: positions[pos], parent: rack1)
        end
      }
      let(:tubes_rack_2) {
        3.times.map do |pos|
          create(:tube, :inside_rack, location: positions[pos], parent: rack2)
        end
      }
      let(:tubes) { [tubes_rack_1, tubes_rack_2].flatten }
      let!(:rack1) { create :tube_rack }
      let!(:rack2) { create :tube_rack }
      let(:layout) {
        all_tubes.each_with_index.map{|tube, i| {asset: tube, location: positions[i]}}
      }

      it 'removes all tubes from the layout from its previous parent' do
        expect(layout_processor.changes_for_tubes_on_unrack(tubes).to_h[:remove_facts]).to include(
          [rack1.uuid, 'contains', tubes_rack_1[0].uuid],
          [rack1.uuid, 'contains', tubes_rack_1[1].uuid],
          [rack1.uuid, 'contains', tubes_rack_1[2].uuid],
          [rack2.uuid, 'contains', tubes_rack_2[0].uuid],
          [rack2.uuid, 'contains', tubes_rack_2[1].uuid],
          [rack2.uuid, 'contains', tubes_rack_2[2].uuid]
        )
      end
      it 'removes the parent from the reracked tubes' do
        expect(layout_processor.changes_for_tubes_on_unrack(tubes).to_h[:remove_facts]).to include(
          [tubes_rack_1[0].uuid, 'parent', rack1.uuid],
          [tubes_rack_1[1].uuid, 'parent', rack1.uuid],
          [tubes_rack_1[2].uuid, 'parent', rack1.uuid],
          [tubes_rack_2[0].uuid, 'parent', rack2.uuid],
          [tubes_rack_2[1].uuid, 'parent', rack2.uuid],
          [tubes_rack_2[2].uuid, 'parent', rack2.uuid]
        )
      end
      it 'removes all previous locations from the tubes of the layout' do
        expect(layout_processor.changes_for_tubes_on_unrack(tubes).to_h[:remove_facts]).to include(
          [tubes_rack_1[0].uuid, 'location', positions[0]],
          [tubes_rack_1[1].uuid, 'location', positions[1]],
          [tubes_rack_1[2].uuid, 'location', positions[2]],
          [tubes_rack_2[0].uuid, 'location', positions[0]],
          [tubes_rack_2[1].uuid, 'location', positions[1]],
          [tubes_rack_2[2].uuid, 'location', positions[2]]
        )
      end

      it 'adds a new reracking record in the destination rack' do
        updates = layout_processor.changes_for_tubes_on_unrack(tubes)
        triples = updates.to_h[:add_facts].select{|t| t[1] == 'rerack'}
        expect(triples.count).to eq(6)
        expect(updates.to_h[:add_facts]).to include(
          *(triples.map{|t| [t[2], 'a', 'Rerack']})
        )
      end
    end
  end

  describe '#changes_for_rack_on_unrack' do
    let(:rack) { create :tube_rack }
    let(:tube1) { create(:tube, :inside_rack, location: "A01", parent: rack) }
    let(:tube2) { create(:tube, :inside_rack, location: "B01", parent: rack) }
    let(:tubes) {[tube1, tube2]}

    it 'removes the relevant properties when removing tubes from the racks' do
      Actions::LayoutProcessor::TUBE_TO_RACK_TRANSFERRABLE_PROPERTIES.push('country')
      tube1.facts << create(:fact, predicate: 'country', object: 'Spain', literal: true)
      tube2.facts << create(:fact, predicate: 'country', object: 'Portugal', literal: true)

      updates = layout_processor.changes_for_rack_on_unrack(rack, tubes)
      expect(updates.to_h[:remove_facts]).to eq(
        [[rack.uuid, 'country', 'Spain'],
        [rack.uuid, 'country', 'Portugal']]
      )
    end
    it 'does not remove non-relevant properties when removing tubes from the rack' do
      property = SecureRandom.uuid
      tube2.facts << create(:fact, predicate: property, object: 'Orange', literal: true)
      updates = layout_processor.changes_for_rack_on_unrack(rack, tubes)
      expect(updates.to_h[:remove_facts]).to be_nil
    end

  end

end
