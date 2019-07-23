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
      state: Step::STATE_RUNNING,
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
      let(:obj) { Parsers::CsvLayout.new("test")}
      it 'converts to right location when less that 2 digit' do
        expect(obj.convert_to_location("A1")).to eq("A01")
        expect(obj.convert_to_location("A01")).to eq("A01")
        expect(obj.convert_to_location("A111")).to eq(nil)
        expect(obj.convert_to_location("")).to eq(nil)
      end
    end

    describe '#filter_empty_lines' do
      let(:obj) { Parsers::CsvLayout.new("test")}
      it 'filters nil elements' do
        lines = [nil,"asdf"]
        expect(obj.filter_empty_lines(lines).length).to eq(1)
        expect(obj.filter_empty_lines(lines)).to eq(["asdf"])
      end
      it 'filters empty lines' do
        lines = ["1234","","5678"]
        expect(obj.filter_empty_lines(lines).length).to eq(2)
        expect(obj.filter_empty_lines(lines)).to eq(["1234", "5678"])
      end
    end

    describe '#filter_no_read_barcodes' do
      let(:obj) { Parsers::CsvLayout.new("test")}
      it "filters lines where the layout display \'No Read\'" do
        lines = [["A01", "1234"],["B01", "No read"], ["C01", "5678"]]
        expect(obj.filter_no_read_barcodes(lines)).to eq([["A01", "1234"], ["C01", "5678"]])
      end
    end

    describe '#barcode_from_line' do
      let(:obj) { Parsers::CsvLayout.new("test")}
      it 'returns the barcode part of a line' do
        expect(obj.barcode_from_line(["A01","F123456"])).to eq("F123456")
      end
    end

    describe '#location_from_line' do
      let(:obj) { Parsers::CsvLayout.new("test")}
      it 'returns the location part of a line' do
        expect(obj.location_from_line(["A01","F123456"])).to eq("A01")
      end
    end

    describe '#no_read_barcode?' do
      let(:obj) { Parsers::CsvLayout.new("test")}
      it 'validates no read strings' do
        expect(obj.no_read_barcode?("NO READ")).to eq(true)
        expect(obj.no_read_barcode?("no read")).to eq(true)
        expect(obj.no_read_barcode?("No Read")).to eq(true)
        expect(obj.no_read_barcode?("adasdf")).to eq(false)
      end
    end

    describe '#valid_location?' do
      let(:obj) { Parsers::CsvLayout.new("test")}
      it 'checks the valid location can have less that 2 digit' do
        expect(obj.valid_location?("A1")).to eq(true)
        expect(obj.valid_location?("A01")).to eq(true)
        expect(obj.valid_location?("A111")).to eq(false)
        expect(obj.valid_location?("")).to eq(false)
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

      context 'when some barcodes are not read during scan (no read in layout)' do
        it 'does not load anything for that location' do
          asset1 = create :asset, barcode: 'FR000001'
          asset2 = create :asset, barcode: 'FR000002'
          content = "A01,#{asset1.barcode}\nB01,No read\nC01,#{asset2.barcode}"
          csv = Parsers::CsvLayout.new(content)
          expect(csv.valid?).to eq(true)
          expect(csv.layout.length).to eq(2)
          expect(csv.layout[0][:asset]).to eq(asset1)
          expect(csv.layout[1][:asset]).to eq(asset2)
        end
      end
    end

    describe "parsing content saved by Excel" do
      it 'parses it correcctly' do
        @csv = Parsers::CsvLayout.new("A01,FR11200002\rA02,FR11200003\n")
        expect(@csv.parse).to eq(true)
      end
    end
  end
end

