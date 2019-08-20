require 'rails_helper'
require 'parsers/csv_layout/line_reader'

RSpec.describe Parsers::CsvLayout::LineReader do
  let(:parser) { Parsers::CsvLayout::LineReader.new(@content)}
  it 'generates a list of lists from the text' do
    @content = "A01,1234\nB01,4567"
    expect(parser.lines).to eq([["A01","1234"],["B01", "4567"]])
  end
  it 'uses carriage return as new line' do
    @content = "A01,1234\rB01,4567"
    expect(parser.lines).to eq([["A01","1234"],["B01", "4567"]])
  end
  it 'ignores the bom header if set' do
    @content = "#{Parsers::CsvLayout::LineReader::BOM_HEADER}A01,1234\nB01,4567"
    expect(parser.lines).to eq([["A01","1234"],["B01", "4567"]])
  end
end
