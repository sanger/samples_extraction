require 'rails_helper'
require 'actions/racking'

RSpec.describe Actions::Racking do
  let(:content) { File.read('test/data/layout.csv') }
  let(:file) { create(:uploaded_file, data: content ) }
  let(:activity) { create(:activity) }
  let(:asset_group) { create(:asset_group, assets: [asset]) }
  let(:fact) { create(:fact, predicate: 'a', object: 'TubeRack') }
  let(:asset) { create :asset, uploaded_file: file, facts: [fact] }
  let(:step_type) { create(:step_type, condition_groups: [condition_group]) }
  let(:step) { create :step,
    activity: activity,
    state: Step::STATE_RUNNING,
    asset_group: asset_group, step_type: step_type }

  let(:condition) { create(:condition, predicate: fact.predicate, object: fact.object) }
  let(:condition_group) { create(:condition_group, conditions: [condition]) }

  include Actions::Racking

  setup do
    allow(Asset).to receive(:find_or_import_asset_with_barcode) do |barcode|
      Asset.find_by(barcode: barcode)
    end
  end

  shared_examples_for 'rack_layout' do
    describe "when linking it with an asset" do
      it 'adds the facts to the asset' do
        expect(asset.facts.count).to eq(1)
        updates = send(method, asset_group)
        updates.apply(step)

        asset.facts.reload
        assets = asset.facts.with_predicate('contains').map(&:object_asset)
        expect(assets.count).to eq(96)
        assets.each do |a|
          expect(a.facts.with_predicate('location').count).to eq(1)
          expect(a.facts.with_predicate('parent').count).to eq(1)
          expect(a.facts.with_predicate('parent').first.object_asset).to eq(asset)
        end
      end

      describe 'with links with previous parents' do
        let(:actual_parent) { create(:asset, uploaded_file: file, facts: [fact]) }
        it 'removes links with the previous parents' do
          send(method, asset_group).apply(step)
          asset.facts.reload
          assets = asset.facts.with_predicate('contains').map(&:object_asset)
          expect(assets.count).to eq(96)
          assets.each do |a|
            expect(a.facts.with_predicate('location').count).to eq(1)
            expect(a.facts.with_predicate('parent').count).to eq(1)
            expect(a.facts.with_predicate('parent').first.object_asset).to eq(asset)
          end

          asset_group = AssetGroup.create(assets: [actual_parent])
          another_step = Step.new(
            activity: activity,
            asset_group: asset_group, step_type: step_type,
            state: Step::STATE_RUNNING
          )
          send(method, asset_group).apply(another_step)

          assets = asset.reload.facts.with_predicate('contains').map(&:object_asset)
          expect(assets.count).to eq(0)

          assets = actual_parent.reload.facts.with_predicate('contains').map(&:object_asset)
          expect(assets.count).to eq(96)
          assets.each do |a|
            expect(a.facts.with_predicate('location').count).to eq(1)
            expect(a.facts.with_predicate('parent').count).to eq(1)
            expect(a.facts.with_predicate('parent').first.object_asset).to eq(actual_parent)
          end
        end
      end

      describe 'with empty slots in the layout .csv' do
        let(:num_empty) { 3 }
        let(:start_pos) { 0 }
        let(:content) {
          add_empty_slots(File.read('test/data/layout.csv'), num_empty, start_pos)
        }
        def add_empty_slots(content, num_empty, start_pos = 0)
          csv = CSV.new(content).to_a
          num_empty.times do |i|
            csv[start_pos + i][1] = 'No Read'
          end
          csv.map do |line|
            line.join(',')
          end.join("\n")
        end

        it 'adds the new facts to the asset and removes the old ones' do
          expect(asset.facts.count).to eq(1)
          send(method, asset_group).apply(step)

          asset.facts.reload
          assets = asset.facts.with_predicate('contains').map(&:object_asset)
          expect(assets.count).to eq(96 - num_empty)
          assets.each_with_index do |a, idx|
            if (idx < start_pos) || (idx >= start_pos + num_empty)
              expect(a.facts.with_predicate('location').count).to eq(1)
              expect(a.facts.with_predicate('parent').count).to eq(1)
              expect(a.facts.with_predicate('parent').first.object_asset).to eq(asset)
            end
          end
        end

      end

    end
  end


  describe '#fact_changes_for_rack_when_unracking_tubes' do
    before do
      @tubes = 15.times.map do |line|
        create(:asset)
      end
      @tubes.each do |tube|
        asset.facts << create(:fact, predicate: 'contains', object_asset: tube)
      end
    end
    it 'removes all the different studies for this rack when all tubes go out' do
      @tubes.first.facts << create(:fact, predicate: 'study_name', object: 'STDY2')
      @tubes.each_with_index do |tube, idx|
        tube.facts << create(:fact, predicate: 'study_name', object: 'STDY1') unless idx == 0
      end
      updates = fact_changes_for_rack_when_unracking_tubes(asset, @tubes)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='study_name'
      end.map { |triple| triple[2] }.sort).to eq(['STDY1', 'STDY2'])
    end

    it 'removes the purpose when all tubes go out' do
      asset.facts << create(:fact, predicate: 'purpose', object: 'DNA Stock Plate')
      @tubes.first.facts << create(:fact, predicate: 'aliquotType', object: 'DNA')
      updates = fact_changes_for_rack_when_unracking_tubes(asset, @tubes)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='purpose'
      end.map { |triple| triple[2] }.sort).to eq(['DNA Stock Plate'])
    end

    it 'only returns the studies of the tubes that are going to be removed' do
      @tubes.first.facts << create(:fact, predicate: 'study_name', object: 'STDY2')
      tubes2 = @tubes.each_with_index.filter_map do |tube, idx|
        unless idx == 0
          tube.facts << create(:fact, predicate: 'study_name', object: 'STDY1')
          tube
        end
      end

      updates = fact_changes_for_rack_when_unracking_tubes(asset, tubes2)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='study_name'
      end.map { |triple| triple[2] }.sort).to eq(['STDY1'])
    end
  end


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
      end.map { |triple| triple[2] }.sort).to eq(['STDY1', 'STDY2'])
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

  describe '#rack_layout' do
    before do
      csv = CSV.new(File.read('test/data/layout.csv')).to_a
      @tubes = csv.map do |line|
        create(:asset, barcode: line[1])
      end
    end
    let(:method) { :rack_layout }
    it_behaves_like('rack_layout')
  end

  describe '#rack_layout_creating_tubes' do
    let(:method) { :rack_layout_creating_tubes }
    it_behaves_like('rack_layout')
  end

end
