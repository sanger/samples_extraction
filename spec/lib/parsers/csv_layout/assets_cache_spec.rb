require 'rails_helper'
require 'parsers/csv_layout/csv_parser'

RSpec.describe 'Parsers::CsvLayout::AssetsCache' do
  let(:content) { File.open('test/data/layout.csv').read }
  let(:parser) { Parsers::CsvLayout::CsvParser.new(content) }
  let(:csv_parsed) { CSV.new(content).to_a }
  let!(:tubes) { csv_parsed.map{|line| create(:asset, barcode: line[1]) } }

  before do
    allow(Asset).to receive(:find_or_import_assets_with_barcodes).with(tubes.map(&:barcode)).and_return(tubes)
  end
  it 'performs a single request with all barcodes in the file' do
    parser.parse
    expect(Asset).to have_received(:find_or_import_assets_with_barcodes).with(tubes.map(&:barcode)).once
  end
end
