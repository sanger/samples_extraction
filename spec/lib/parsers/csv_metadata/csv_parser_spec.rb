require 'rails_helper'
require 'parsers/csv_metadata/csv_parser'
require 'parsers/csv_layout/line_parser'
require 'parsers/csv_layout/barcode_parser'
require 'parsers/csv_layout/location_parser'
require 'parsers/csv_layout/validators/any_barcode_validator'
require 'parsers/csv_layout/validators/location_validator'

RSpec.describe Parsers::CsvMetadata::CsvParser do

  describe "parses a metadata file" do
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

      @content = File.open('test/data/metadata.csv').read
      @assets = 96.times.map do |i|
        FactoryBot.create(:asset, {
          :barcode => 'FR'+(11200002 + i).to_s
        })
      end
    end

    describe "with valid content" do
      it 'parses correctly' do
        @csv = Parsers::CsvMetadata::CsvParser.new(@content)

        expect(@csv.parse).to eq(true)
        expect(@csv).to be_valid
      end
      it 'returns the right parsed content' do
        @csv = Parsers::CsvMetadata::CsvParser.new(@content)
        expect(@csv.metadata.length).to eq(96)
        expect(@csv.metadata[0]).to eq({
          'barcode' => 'DN1001001', 'location' => 'A01', 'data1' => '111', 'data2'=> '444'
          })
        expect(@csv.metadata[95]).to eq({
          'barcode' => 'DN1001001', 'location' => 'H12', 'data1' => '123', 'data2'=> '456'
          })
      end
    end

    describe "parsing content saved from Excel" do
      it 'parses it correctly' do
        @csv = Parsers::CsvMetadata::CsvParser.new("location,barcode,data\rA01,DN1001001,1\rA02,DN1001001,2")
        expect(@csv).to be_valid
      end
    end
  end
end

