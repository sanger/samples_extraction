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
    end
  end

  describe '#changes_for_rack_on_unrack' do
    let(:rack) { create :tube_rack }

    let(:tubes) {
      15.times.map do |pos|
        create(:tube, :inside_rack, location: positions[pos], parent: rack)
      end
    }

    it 'removes all the different studies for this rack when all tubes go out' do
      tubes.first.facts << create(:fact, predicate: 'study_name', object: 'STDY2')
      tubes.each_with_index do |tube, idx|
        tube.facts << create(:fact, predicate: 'study_name', object: 'STDY1') unless idx == 0
      end
      updates = layout_processor.changes_for_rack_on_unrack(rack, tubes)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='study_name'
      end.map{|triple| triple[2]}.sort).to eq(['STDY1', 'STDY2'])
    end

    it 'removes the purpose when all tubes go out' do
      rack.facts << create(:fact, predicate: 'purpose', object: 'DNA Stock Plate')
      tubes.first.facts << create(:fact, predicate: 'aliquotType', object: 'DNA')
      updates = layout_processor.changes_for_rack_on_unrack(rack, tubes)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='purpose'
      end.map{|triple| triple[2]}.sort).to eq(['DNA Stock Plate'])
    end

    it 'only returns the studies of the tubes that are going to be removed' do
      tubes.first.facts << create(:fact, predicate: 'study_name', object: 'STDY2')
      tubes2 = tubes.each_with_index.map do |tube, idx|
        unless idx == 0
          tube.facts << create(:fact, predicate: 'study_name', object: 'STDY1')
          tube
        end
      end.compact
      updates = layout_processor.changes_for_rack_on_unrack(rack, tubes2)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='study_name'
      end.map{|triple| triple[2]}.sort).to eq(['STDY1'])
    end
  end

end
