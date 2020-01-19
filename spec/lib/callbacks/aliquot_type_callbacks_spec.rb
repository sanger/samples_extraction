require 'rails_helper'

RSpec.describe 'Callbacks::AliquotTypeCallbacks' do
  let(:updates) { FactChanges.new }
  let(:inference) { Step.new }
  let(:aliquots) { ['DNA', 'RNA', 'other'] }
  let(:rack) { create :tube_rack }

  context 'when changing aliquotType' do
    context 'when adding the aliquot type' do
      it 'adds the plate purpose' do
        aliquots.each do |aliquot|
          purpose = Callbacks::AliquotTypeCallbacks.purpose_for_aliquot(aliquot)
          updates.add(rack, 'aliquotType', aliquot)
          expect{ updates.apply(inference) }.to change{
            Fact.where(asset: rack, predicate: 'purpose', object: purpose).count
          }.from(0).to(1)
        end
      end
    end

    context 'when removing the aliquot type' do
      it 'removes the plate purpose' do
        aliquots.each do |aliquot|
          purpose = Callbacks::AliquotTypeCallbacks.purpose_for_aliquot(aliquot)
          rack.facts << create(:fact, predicate: 'purpose', object: purpose, literal: true)
          rack.facts << create(:fact, predicate: 'aliquotType', object: aliquot, literal: true)
          updates.remove_where(rack, 'aliquotType', aliquot)
          expect{ updates.apply(inference) }.to change{
            Fact.where(asset: rack, predicate: 'purpose', object: purpose).count
          }.from(1).to(0)
        end
      end
    end
  end

end
