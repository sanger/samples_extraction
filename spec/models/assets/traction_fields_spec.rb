require 'rails_helper'

RSpec.describe 'TractionFields' do
  shared_examples_for 'a method that converts from uuid_str_format ot uuid' do
    let(:uuid) { SecureRandom.uuid }

    context 'when the uuid has been converted for internal process' do
      let(:store_uuid) { TokenUtil.uuid_to_uuid_str(uuid) }
      it 'returns a valid uuid' do
        asset = create(:asset)
        asset.facts << create(:fact, predicate: predicate, object: store_uuid)

        expect(asset.send(method)).to eq(uuid)
      end
    end
    context 'when storing a normal uuid' do
      let(:store_uuid) { uuid }
      it 'returns a valid uuid' do
        asset = create(:asset)
        asset.facts << create(:fact, predicate: predicate, object: store_uuid)

        expect(asset.send(method)).to eq(uuid)
      end
    end
  end
  context '#sample_uuid' do
    let(:predicate) { 'sample_tube' }
    let(:method) { :sample_uuid }
    it_behaves_like 'a method that converts from uuid_str_format ot uuid'
  end
  context '#study_uuid' do
    let(:predicate) { 'study_uuid' }
    let(:method) { :study_uuid }
    it_behaves_like 'a method that converts from uuid_str_format ot uuid'
  end

end
