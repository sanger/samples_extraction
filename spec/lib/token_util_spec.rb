require 'rails_helper'

RSpec.describe TokenUtil do
  let(:uuid) { "00000000-0000-0000-0000-000000000001" }
  let(:wildcard) { "?variablename" }
  context '#is_uuid?' do
    it 'recognises an uuid' do
      expect(TokenUtil.is_uuid?(uuid)).to eq(true)
    end
  end
  context '#is_wildcard?' do
    it 'recognises a string that represents a wildcard' do
      expect(TokenUtil.is_wildcard?(wildcard)).to eq(true)
    end
  end
end
