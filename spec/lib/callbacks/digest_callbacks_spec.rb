require 'rails_helper'

RSpec.describe 'Callbacks::DigestCallbacks' do
  let(:updates) { FactChanges.new }
  let(:inference) { Step.new }
  let(:rack) { create :tube_rack }

  context 'when changing the digest of an asset' do
    let(:remote_digest) {"1234"}

    let(:asset) { create :asset}

    it 'sets the remotes digest into the asset' do
      updates.add(asset, 'remote_digest', remote_digest)
      expect{updates.apply(inference)}.to change{asset.remote_digest}.from(nil).to(remote_digest)
    end

    it 'adds the remote digest fact to the asset' do
      updates.add(asset, 'remote_digest', remote_digest)
      expect{updates.apply(inference)}.to change{asset.facts.where(predicate: 'remote_digest').count}.from(0).to(1)
    end

    it 'adds an add operation for it' do
      updates.add(asset, 'remote_digest', remote_digest)
      updates.apply(inference)
      inference.reload
      inference.operations.reload
      expect(inference.operations.where(action_type: 'addFacts', predicate: 'remote_digest').count).not_to eq(0)

    end
  end
end
