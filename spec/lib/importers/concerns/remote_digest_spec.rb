require 'rails_helper'
require 'remote_assets_helper'
require 'importers/concerns/annotator'

RSpec.describe 'Importers::Concerns::RemoteDigest' do
  include RemoteAssetsHelper

  let(:remote_asset) { build_remote_plate }
  let(:asset) { create :asset }
  let(:instance) { Importers::Concerns::Annotator.new(asset, remote_asset) }

  context 'with the InstanceMethods' do
    context '#digest_for_remote_asset' do
      it 'returns a string with the digest hash of the remote asset' do
        expect(instance.digest_for_remote_asset.kind_of?(String)).to be_truthy
      end
    end
    context '#has_changes_between_local_and_remote?' do
      it 'returns true if there are changes' do
        expect(instance.has_changes_between_local_and_remote?).to be_truthy
      end
      it 'returns false if there are no changes' do
        asset.update_attributes(remote_digest: instance.digest_for_remote_asset)
        expect(instance.has_changes_between_local_and_remote?).to be_falsy
      end
    end
  end

  context 'with the ClassMethods' do
    context '#signature_for_remote' do
      it 'returns a string' do
        expect(Importers::Concerns::Annotator.signature_for_remote(instance.remote_asset).kind_of?(String)).to be_truthy
      end
    end
  end
end
