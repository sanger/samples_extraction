require 'rails_helper'
require 'remote_assets_helper'
require 'importers/barcodes_importer'

RSpec.describe 'Importers::Concerns::RemoteDigest' do
  include RemoteAssetsHelper

  let(:remote_asset) { build_remote_plate }
  let(:barcodes) { ['1', '2']}
  let(:instance) { Importers::BarcodesImporter.new(barcodes) }

  context '#digest_for_remote_asset' do
    it 'returns a string with the digest hash of the remote asset' do
      expect(instance.digest_for_remote_asset(remote_asset).kind_of?(String)).to be_truthy
    end
  end

  context '#signature_for_remote' do
    it 'returns a string' do
      expect(instance.signature_for_remote(remote_asset).kind_of?(String)).to be_truthy
    end
  end

  context '#changed_remote?' do
    it 'detects a change when the stored digest is nil' do
      plate = create :plate, remote_digest: nil
      expect(instance.changed_remote?(plate, remote_asset)).to be_truthy
    end
    it 'detects the change when the stored digest is different from the actual' do
      plate = create :plate, remote_digest: "1234"
      expect(instance.changed_remote?(plate, remote_asset)).to be_truthy
    end
    it 'does not detect change when stored digest is equal to the actual' do
      digest = instance.digest_for_remote_asset(remote_asset)
      plate = create :plate, remote_digest: digest
      expect(instance.changed_remote?(plate, remote_asset)).to be_falsy
    end
  end

  context '#update_digest_with_remote' do
    it 'updates the digest with the remote asset provided' do
      plate = create :plate, remote_digest: nil
      digest = instance.digest_for_remote_asset(remote_asset)
      expect{
        instance.update_digest_with_remote(plate, remote_asset)
      }.to change{plate.remote_digest}.from(nil).to(digest)
    end
  end
end
