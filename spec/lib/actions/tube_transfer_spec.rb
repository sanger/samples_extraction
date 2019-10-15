require 'rails_helper'
require 'actions/tube_transfer'

RSpec.describe 'Actions::TubeTransfer' do
  include Actions::TubeTransfer

  context '#transfer_tubes' do
    let(:source) { create :asset }
    let(:destination) { create :asset }
    let(:quoted_study_uuid) { TokenUtil.quote(SecureRandom.uuid)}
    before do
      source.facts << create(:fact, predicate: 'study_uuid', object: quoted_study_uuid)
    end
    it 'transfers study_uuid' do
      updates = transfer_tubes(source, destination)
      expect(updates.to_h[:add_facts].select{|t| t[1]=='study_uuid'}.first[2]).to eq(quoted_study_uuid)
    end
  end
end
