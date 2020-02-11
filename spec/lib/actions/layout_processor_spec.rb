require 'rails_helper'
require 'actions/layout_processor'

RSpec.describe Actions::LayoutProcessor do
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

  let(:csv_parsed) { CSV.new(content).to_a }
  let!(:tubes) { csv_parsed.map{|line| create(:asset, barcode: line[1]) } }

  setup do
    allow(Asset).to receive(:find_or_import_asset_with_barcode) do |barcode|
      Asset.find_by(barcode: barcode)
    end
    allow(Asset).to receive(:find_or_import_assets_with_barcodes) do |barcodes|
      Asset.where(barcode: barcodes)
      #barcodes.map{|barcode| Asset.find_by(barcode: barcode)}
    end

  end


  describe "when linking it with an asset" do
    it 'adds the facts to the asset' do
      expect(asset.facts.count).to eq(1)
      updates = Actions::LayoutProcessor.new(asset_group: asset_group).changes
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
        Actions::LayoutProcessor.new(asset_group: asset_group).changes.apply(step)
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
        Actions::LayoutProcessor.new(asset_group: asset_group).changes.apply(another_step)

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
        Actions::LayoutProcessor.new(asset_group: asset_group).changes.apply(step)

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
