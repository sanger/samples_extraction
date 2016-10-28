require 'rails_helper'
require 'parsers/csv_order'

RSpec.describe Parsers::CsvOrder do

  def index_to_location_str(i)
    letters = ('A'..'H').to_a
    "#{letters[(i % 8)]}#{(i/8).to_i+1}"
  end

  describe "parses an order" do
    setup do
      @content = File.open('test/data/order.csv')
      @asset_sample = FactoryGirl.create(:asset, :barcode => '5180002041715')
      @rack = FactoryGirl.create(:asset)
      @assets_dst = 96.times.map do |i|
        asset = FactoryGirl.create(:asset, {
          :barcode => 'FR'+(11200002 + i).to_s
        })
        asset.add_facts(FactoryGirl.create(:fact, {
          :predicate => 'location', :object => index_to_location_str(i)
          }))
        asset.add_facts(FactoryGirl.create(:fact, {
          :predicate => 'parent', :object_asset => @rack
          }))
        asset
      end
      @rack.add_facts(@assets_dst.map{|a| FactoryGirl.create(:fact, {
        :predicate => 'contains',
        :object_asset => a
        })})
    end

    describe "with valid content" do
      it 'parses correctly' do
        @csv = Parsers::CsvOrder.new(@content)

        expect(@csv.parse).to eq(true)
        expect(@csv.valid?).to eq(true)
      end

      it 'recognise incorrect csv files' do
        @csv = Parsers::CsvOrder.new('1,2,3,4,5')
        expect(@csv.valid?).to eq(false)
      end
    end

    describe "when linking it with an asset" do
      setup do
        @step_type = FactoryGirl.create(:step_type)
        @asset_group = FactoryGirl.create(:asset_group)
        @step = FactoryGirl.create(:step, {
          :step_type =>@step_type,
          :asset_group => @asset_group
          })
      end

      it 'adds the facts to the asset' do
        @csv = Parsers::CsvOrder.new(@content)
        @csv.add_facts_to(@rack, @step)

        @rack.facts.reload
        expect(@asset_sample.facts.with_predicate('transfer').first.object_asset).to eq(@rack.facts.with_predicate('contains').first.object_asset)
        expect(@rack.facts.with_predicate('contains').first.object_asset.facts.with_predicate('transferredFrom').first.object_asset).to eq(@asset_sample)
      end

    end
  end
end
