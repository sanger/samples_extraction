require 'rails_helper'
require 'parsers/csv_layout'
require 'csv'

RSpec.describe Parsers::CsvLayout, akeredu: true do

  describe "parses a layout" do
    let(:activity) { create(:activity)}
    let(:asset_group) { create(:asset_group) }
    let(:step_type) {create(:step_type)}
    let(:step) { create :step,
      activity: activity,
      asset_group: asset_group, step_type: step_type }

    setup do
      @content = File.open('test/data/layout.csv')
      @assets = 96.times.map do |i|
        FactoryBot.create(:asset, {
          :barcode => 'FR'+(11200002 + i).to_s
        })
      end
    end


    describe '#convert_to_location' do
      let(:obj) { Parsers::CsvLayout.new("test", step)}
      it 'converts to right location when less that 2 digit' do
        expect(obj.convert_to_location("A1")).to eq("A01")
        expect(obj.convert_to_location("A01")).to eq("A01")
        expect(obj.convert_to_location("A111")).to eq(nil)
        expect(obj.convert_to_location("")).to eq(nil)
      end
    end

    describe '#no_read_barcode?' do
      let(:obj) { Parsers::CsvLayout.new("test", step)}
      it 'validates no read strings' do
        expect(obj.no_read_barcode?("NO READ")).to eq(true)
        expect(obj.no_read_barcode?("no read")).to eq(true)
        expect(obj.no_read_barcode?("No Read")).to eq(true)
        expect(obj.no_read_barcode?("adasdf")).to eq(false)
      end
    end

    describe '#valid_location?' do
      let(:obj) { Parsers::CsvLayout.new("test", step)}
      it 'checks the valid location can have less that 2 digit' do
        expect(obj.valid_location?("A1")).to eq(true)
        expect(obj.valid_location?("A01")).to eq(true)
        expect(obj.valid_location?("A111")).to eq(false)
        expect(obj.valid_location?("")).to eq(false)
      end
    end

    describe "with valid content" do
      it 'parses correctly' do
        @csv = Parsers::CsvLayout.new(@content, step)

        expect(@csv.parse).to eq(true)
        expect(@csv.valid?).to eq(true)
      end

      it 'recognise incorrect csv files' do
        @csv = Parsers::CsvLayout.new('1,2,3,4,5', step)
        expect(@csv.valid?).to eq(false)
      end
    end

  end
end
