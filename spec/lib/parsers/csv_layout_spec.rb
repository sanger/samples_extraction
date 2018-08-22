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
