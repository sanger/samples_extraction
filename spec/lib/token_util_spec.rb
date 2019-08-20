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
  context '#pad' do
    it 'pads a string with a character using a length' do
      expect(TokenUtil.pad("1234", "0", 8)).to eq("00001234")
      expect(TokenUtil.pad("1234", "0", 2)).to eq("1234")
    end
  end
  context '#generate_positions' do
    it 'generates a padded list of well positions' do
      expect(TokenUtil.generate_positions(('A'..'C').to_a, ('1'..'3').to_a)).to eq(
        ["A01","A02", "A03", "B01","B02", "B03", "C01","C02", "C03"]
      )
    end
  end
end
