require 'rails_helper'

RSpec.describe 'Actions::Layout::Racking' do
  describe '#fact_changes_for_rack_when_racking_tubes' do
    before do
      @tubes = 15.times.map do |line|
        create(:asset)
      end
    end
    it 'returns all the different studies for this rack' do
      @tubes.first.facts << create(:fact, predicate: 'study_name', object: 'STDY2')
      @tubes.each_with_index do |tube, idx|
        tube.facts << create(:fact, predicate: 'study_name', object: 'STDY1') unless idx == 0
      end

      updates = fact_changes_for_rack_when_racking_tubes(asset, @tubes)
      expect(updates.to_h[:add_facts].select do |triple|
        triple[1]=='study_name'
      end.map{|triple| triple[2]}.sort).to eq(['STDY1', 'STDY2'])
    end
    it 'generates the DNA stock plate purpose' do
      @tubes.each_with_index do |tube, idx|
        tube.facts << create(:fact, predicate: 'aliquotType', object: 'DNA') unless idx == 0
      end
      updates = fact_changes_for_rack_when_racking_tubes(asset, @tubes)
      expect(updates.to_h[:add_facts].select do |triple|
        triple[1]=='purpose'
      end.first[2]).to eq('DNA Stock Plate')
    end
    it 'generates the RNA stock plate purpose' do
      @tubes.each_with_index do |tube, idx|
        tube.facts << create(:fact, predicate: 'aliquotType', object: 'RNA') unless idx == 0
      end
      updates = fact_changes_for_rack_when_racking_tubes(asset, @tubes)
      expect(updates.to_h[:add_facts].select do |triple|
        triple[1]=='purpose'
      end.first[2]).to eq('RNA Stock Plate')
    end
  end
end
