require 'rails_helper'
require 'parsers/csv_layout/csv_parser'
require 'parsers/csv_layout/line_parser'
require 'parsers/csv_layout/barcode_parser'
require 'parsers/csv_layout/location_parser'
require 'parsers/csv_layout/validators/any_barcode_validator'
require 'parsers/csv_layout/validators/location_validator'

RSpec.describe Parsers::CsvLayout::CsvParser do

  describe "parses a layout" do
    let(:activity) { create(:activity)}
    let(:asset_group) { create(:asset_group) }
    let(:step_type) {create(:step_type)}
    let(:step) { create :step,
      activity: activity,
      state: Step::STATE_RUNNING,
      asset_group: asset_group, step_type: step_type }

    setup do
      allow(Asset).to receive(:find_or_import_asset_with_barcode) do |barcode|
        Asset.find_by(barcode: barcode)
      end

      @content = File.open('test/data/layout.csv').read
      @assets = 96.times.map do |i|
        FactoryBot.create(:asset, {
          :barcode => 'FR'+(11200002 + i).to_s
        })
      end
    end

    describe "with valid content" do
      it 'parses correctly' do
        @csv = Parsers::CsvLayout::CsvParser.new(@content)

        expect(@csv.parse).to eq(true)
        expect(@csv).to be_valid
      end

      it 'recognise incorrect csv files' do
        @csv = Parsers::CsvLayout::CsvParser.new('1,2,3,4,5')
        expect(@csv).to be_invalid
      end

      context 'when some barcodes are not read during scan (no read in layout)' do
        it 'does not load anything for that location' do
          asset1 = create :asset, barcode: 'FR000001'
          asset2 = create :asset, barcode: 'FR000002'
          content = "A01,#{asset1.barcode}\nB01,No read\nC01,#{asset2.barcode}"
          csv = Parsers::CsvLayout::CsvParser.new(content)
          expect(csv).to be_valid
          expect(csv.layout.length).to eq(2)
          expect(csv.layout[0][:asset]).to eq(asset1)
          expect(csv.layout[1][:asset]).to eq(asset2)
        end
      end
    end

    describe "parsing content saved from Excel" do
      it 'parses it correctly' do
        @csv = Parsers::CsvLayout::CsvParser.new("A01,FR11200002\rA02,FR11200003")
        expect(@csv).to be_valid
      end
      it 'detects tube duplication' do
          asset1 = create :asset, barcode: 'FR000001'
          content = "A01,#{asset1.barcode}\nB01,#{asset1.barcode}"
          csv = Parsers::CsvLayout::CsvParser.new(content)
          expect(csv).not_to be_valid
          expect(csv.error_list.length).to eq(1)
      end
      it 'detects location duplication' do
          asset1 = create :asset, barcode: 'FR000001'
          asset2 = create :asset, barcode: 'FR000002'
          content = "A01,#{asset1.barcode}\nA01,#{asset2.barcode}"
          csv = Parsers::CsvLayout::CsvParser.new(content)
          expect(csv).not_to be_valid
          expect(csv.error_list.length).to eq(1)
      end
    end
  end

end

