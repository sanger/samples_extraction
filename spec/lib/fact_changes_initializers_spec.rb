require 'rails_helper'
require 'fact_changes'

RSpec.describe 'FactChangesInitializers' do

  context 'Callbacks' do
    let(:updates) { FactChanges.new }
    let(:inference) { Step.new }
    let(:aliquots) { ['DNA', 'RNA', 'other'] }
    let(:rack) { create :tube_rack }

    context 'when changing aliquotType' do
      context 'when adding the aliquot type' do
        it 'adds the plate purpose' do
          aliquots.each do |aliquot|
            purpose = FactChangesInitializers::Callbacks.purpose_for_aliquot(aliquot)
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
            purpose = FactChangesInitializers::Callbacks.purpose_for_aliquot(aliquot)
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
    context 'when changing barcode' do
      let(:barcode) {"1234"}

      context 'when adding a barcode fact' do
        let(:asset) { create :asset}

        it 'sets the barcode into the barcode column of the asset' do
          updates.add(asset, 'barcode', barcode)
          expect{updates.apply(inference)}.to change{asset.barcode}.from(nil).to(barcode)
        end
      end
      context 'when removing a barcode fact' do
        let(:asset) { create :asset, barcode: barcode}

        it 'removes the barcode from the column of the asset' do
          updates.remove_where(asset, 'barcode', barcode)
          expect{updates.apply(inference)}.to change{asset.barcode}.from(barcode).to(nil)
        end
      end
    end
  end
end
