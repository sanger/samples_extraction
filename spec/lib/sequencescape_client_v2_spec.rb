# frozen_string_literal: true

require 'rails_helper'
require './lib/sequencescape_client_v2'

RSpec.describe SequencescapeClientV2 do
  describe 'SequencescapeClientV2::Model' do
    it 'sets the api base url in an abstract base class' do
      expect(SequencescapeClientV2::Model.site).to eq("#{Rails.configuration.ss_api_v2_uri}/api/v2/")
    end

    it 'sets the sync attribute to false' do
      expect(SequencescapeClientV2::Model.sync).to be_falsey
    end

    it 'sets the api key in the connection options headers' do
      headers = SequencescapeClientV2::Model.connection_options[:headers]
      expect(headers['X-Sequencescape-Client-Id']).to eq(Rails.configuration.ss_authorisation)
    end
  end

  # Checks a class using the SequencescapeClientV2::Model class has the correct data
  describe 'SequencescapeClientV2::Plate' do
    it 'sets the api base url in an abstract base class' do
      expect(SequencescapeClientV2::Plate.site).to eq("#{Rails.configuration.ss_api_v2_uri}/api/v2/")
    end

    it 'sets the sync attribute to true' do
      expect(SequencescapeClientV2::Plate.sync).to be_truthy
    end

    it 'sets the api key in the connection options headers' do
      headers = SequencescapeClientV2::Plate.connection_options[:headers]
      expect(headers['X-Sequencescape-Client-Id']).to eq(Rails.configuration.ss_authorisation)
    end

    it 'has the api key header set correctly in the requests' do
      # We can assert that the resource has the correct api key in the headers by the fact it is
      # being successfully stubbed
      stub_request(:get, %r{api/v2/plates})
        # If you changed this header key or value it would fail as it would not reflect reality
        .with(headers: { 'X-Sequencescape-Client-Id' => 'test' })
        .to_return(File.new('./spec/support/responses/sequencescape/v2/plate_uuid_response.txt'))
      plate = SequencescapeClientV2::Plate.first
      expect(plate.type).to eq('plates')
    end
  end
end
