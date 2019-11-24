require 'rails_helper'
require 'sequencescape_client'

RSpec.describe 'SequencescapeClient' do
  before do
    allow(SequencescapeClientV2::Plate).to receive(:where)
    allow(SequencescapeClientV2::Tube).to receive(:where)
    allow(SequencescapeClientV2::Well).to receive(:where)
  end
  context '#find_by' do
    let(:assets) { 3.times.map{ create(:asset) }}
    let(:uuids) { assets.map(&:uuid) }
    let(:params) { { uuid: uuids } }
    it 'performs one request for each asset to match all possible elements' do
      SequencescapeClient.find_by(params)
      expect(SequencescapeClientV2::Plate).to have_received(:where).with(params)
      expect(SequencescapeClientV2::Tube).to have_received(:where).with(params)
      expect(SequencescapeClientV2::Well).to have_received(:where).with(params)
    end
  end
end
