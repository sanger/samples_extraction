require 'rails_helper'
require 'actions/racking'

RSpec.describe Actions::Racking do
  let(:content) { File.open('test/data/layout.csv').read }
  let(:file) { create(:uploaded_file, data: content )}
  let(:activity) { create(:activity) }
  let(:asset_group) { create(:asset_group, assets: [asset]) }
  let(:fact) { create(:fact, predicate: 'a', object: 'TubeRack')}
  let(:asset) { create :asset, uploaded_file: file, facts: [fact] }
  let(:step_type) {create(:step_type, condition_groups: [condition_group]) }
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
    allow(Asset).to receive(:find_or_import_assets_with_barcodes) do |barcodes|
      Asset.where(barcode: barcodes)
      #barcodes.map{|barcode| Asset.find_by(barcode: barcode)}
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

          assets = asset.facts.with_predicate('contains').map(&:object_asset)
          expect(assets.count).to eq(0)

          assets = actual_parent.facts.with_predicate('contains').map(&:object_asset)
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
          add_empty_slots(File.open('test/data/layout.csv').read, num_empty, start_pos)
        }
        def add_empty_slots(content, num_empty, start_pos=0)
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

  describe '#changes_for_tubes_on_unrack' do
    context 'when receiving a layout' do
      let(:positions) { TokenUtil.generate_positions(('A'..'F').to_a, (1..12).to_a) }
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
        expect(changes_for_tubes_on_unrack(tubes).to_h[:remove_facts]).to include(
          [rack1.uuid, 'contains', tubes_rack_1[0].uuid],
          [rack1.uuid, 'contains', tubes_rack_1[1].uuid],
          [rack1.uuid, 'contains', tubes_rack_1[2].uuid],
          [rack2.uuid, 'contains', tubes_rack_2[0].uuid],
          [rack2.uuid, 'contains', tubes_rack_2[1].uuid],
          [rack2.uuid, 'contains', tubes_rack_2[2].uuid]
        )
      end
      it 'removes the parent from the reracked tubes' do
        expect(changes_for_tubes_on_unrack(tubes).to_h[:remove_facts]).to include(
          [tubes_rack_1[0].uuid, 'parent', rack1.uuid],
          [tubes_rack_1[1].uuid, 'parent', rack1.uuid],
          [tubes_rack_1[2].uuid, 'parent', rack1.uuid],
          [tubes_rack_2[0].uuid, 'parent', rack2.uuid],
          [tubes_rack_2[1].uuid, 'parent', rack2.uuid],
          [tubes_rack_2[2].uuid, 'parent', rack2.uuid]
        )
      end
      it 'removes all previous locations from the tubes of the layout' do
        expect(changes_for_tubes_on_unrack(tubes).to_h[:remove_facts]).to include(
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

  describe '#changes_for_destination_rack_on_unrack' do
    it 'adds a new reracking record in the destination rack' do
    end
    it 'updates the information of the original racks from the tubes' do
    end
  end


  describe '#changes_for_rack_on_unrack' do
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
      updates = changes_for_rack_on_unrack(asset, @tubes)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='study_name'
      end.map{|triple| triple[2]}.sort).to eq(['STDY1', 'STDY2'])
    end

    it 'removes the purpose when all tubes go out' do
      asset.facts << create(:fact, predicate: 'purpose', object: 'DNA Stock Plate')
      @tubes.first.facts << create(:fact, predicate: 'aliquotType', object: 'DNA')
      updates = changes_for_rack_on_unrack(asset, @tubes)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='purpose'
      end.map{|triple| triple[2]}.sort).to eq(['DNA Stock Plate'])
    end

    it 'only returns the studies of the tubes that are going to be removed' do
      @tubes.first.facts << create(:fact, predicate: 'study_name', object: 'STDY2')
      tubes2 = @tubes.each_with_index.map do |tube, idx|
        unless idx == 0
          tube.facts << create(:fact, predicate: 'study_name', object: 'STDY1')
          tube
        end
      end.compact

      updates = changes_for_rack_on_unrack(asset, tubes2)
      expect(updates.to_h[:remove_facts].select do |triple|
        triple[1]=='study_name'
      end.map{|triple| triple[2]}.sort).to eq(['STDY1'])
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

  describe '#rack_layout' do
    before do
      csv = CSV.new(File.open('test/data/layout.csv').read).to_a
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
