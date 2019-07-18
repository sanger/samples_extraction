require 'rails_helper'
require 'parsers/csv_layout_any_barcode'

RSpec.describe Parsers::CsvLayoutAnyBarcode do
  let(:activity) { create(:activity)}
  let(:asset_group) { create(:asset_group) }
  let(:step_type) {create(:step_type)}
  let(:step) { create :step,
    activity: activity,
    state: Step::STATE_RUNNING,
    asset_group: asset_group, step_type: step_type
  }
  let(:positions) {
    TokenUtil.generate_positions(("A".."H").to_a, (1..12).to_a)
  }

  setup do
    @assets = 96.times.map do |i|
      FactoryBot.create(:asset, {
        :barcode => 'NT'+(11200002 + i).to_s
      })
    end
    @content = positions.zip(@assets.map(&:barcode)).map{|a,b| [a,b].join(',')}.join("\n")
  end

  context 'when providing a layout with normal tube barcodes' do
    it 'allows you to parse the file' do
      @csv = Parsers::CsvLayoutAnyBarcode.new(@content)
      expect(@csv.parse).to eq(true)
      expect(@csv.valid?).to eq(true)
    end
  end
end
