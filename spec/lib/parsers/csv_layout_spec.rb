require 'rails_helper'
require 'parsers/csv_layout'

RSpec.describe Parsers::CsvLayout do

  describe "parses a layout" do
    setup do
      @content = File.open('test/data/layout.csv')
      @assets = 96.times.map do |i|
        FactoryGirl.create(:asset, {
          :barcode => 'FR'+(11200002 + i).to_s
        })
      end
    end

    describe "with valid content" do
      it 'parses correctly' do
        @csv = Parsers::CsvLayout.new(@content)
        expect(@csv.parse).to eq(true)
        expect(@csv.valid?).to eq(true)
      end

      it 'recognise incorrect csv files' do
        @csv = Parsers::CsvLayout.new('1,2,3,4,5')
        expect(@csv.valid?).to eq(false)
      end
    end

    describe "when linking it with an asset" do
      setup do
        @asset = FactoryGirl.create(:asset)
        @step_type = FactoryGirl.create(:step_type)
        @asset_group = FactoryGirl.create(:asset_group)
        @step = FactoryGirl.create(:step, {
          :step_type =>@step_type,
          :asset_group => @asset_group
          })
      end

      it 'adds the facts to the asset' do
        @csv = Parsers::CsvLayout.new(@content)
        expect(@asset.facts.count).to eq(0)
        @csv.add_facts_to(@asset, @step)
        @asset.facts.reload
        expect(@asset.facts.with_predicate('contains').count).to eq(96)
        @assets.each do |a|
          expect(a.facts.with_predicate('location').count).to eq(1)
          expect(a.facts.with_predicate('parent').count).to eq(1)
          expect(a.facts.with_predicate('parent').first.object_asset).to eq(@asset)
        end
      end

      describe 'with links with previous parents' do
        setup do
          @former_parent = FactoryGirl.create(:asset)
          @assets.each_with_index do |a, location_index|
            a.facts << [FactoryGirl.create(:fact, {
              :predicate => 'parent',
              :object_asset => @former_parent
            }),FactoryGirl.create(:fact, {
              :predicate => 'location',
              :object => location_index.to_s
              })]
          end
        end

        it 'removes links with the previous parents' do
          @csv = Parsers::CsvLayout.new(@content)
          expect(@asset.facts.count).to eq(0)
          @csv.add_facts_to(@asset, @step)
          @asset.facts.reload
          expect(@asset.facts.with_predicate('contains').not_to_remove.count).to eq(96)
          @assets.each do |a|
            expect(a.facts.with_predicate('location').not_to_remove.count).to eq(1)
            expect(a.facts.with_predicate('parent').not_to_remove.count).to eq(1)
            expect(a.facts.with_predicate('parent').not_to_remove.first.object_asset).to eq(@asset)
          end
        end
      end
    end
  end
end
