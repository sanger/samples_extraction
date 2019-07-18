require 'rails_helper'

require Rails.root.to_s+'/script/runners/transfer_tubes_to_tube_rack_by_position'


RSpec.describe 'TransferTubesToTubeRackByPosition' do
  let(:wells) {
    5.times.each_with_index.map do |i|
      create(:asset, facts: [
        create(:fact, predicate: 'a', object: 'Well'),
        create(:fact, predicate: 'location', object: "A0#{i}")
      ])
    end
  }
  let(:rack) { create(:asset, facts: [
    create(:fact, predicate: 'a', object: 'TubeRack'),
    wells.map{|w| create(:fact, predicate: 'contains', object_asset_id: w.id)}
    ].flatten)}
  let(:tubes) {
    5.times.map{ create(:asset, facts: [create(:fact, predicate: 'a', object: 'Tube')]) }
  }
  let(:instance) {
    TransferTubesToTubeRackByPosition.new(asset_group: group)
  }
  context 'when it receives a rack and a set of tubes' do
    let(:group) { create(:asset_group, assets: [rack, tubes].flatten)}
    context 'when the tubes do not relate with the rack' do
      it 'does not perform any changes' do
        expect(instance.process.to_h.keys.length).to eq(0)
      end
    end
    context 'when the tubes relate with the rack' do
      before do
        tubes.each do |t|
          t.facts << create(:fact, predicate: 'transferToTubeRackByPosition', object_asset_id: rack.id)
        end
      end
      context 'when only some of the tubes are related with the rack' do
        let(:unrelated_tubes) {
          5.times.map{ create(:asset, facts: [create(:fact, predicate: 'a', object: 'Tube')]) }
        }
        before do
          group.assets << unrelated_tubes
        end
        it 'transfers the related tubes' do
          added_facts = instance.process.to_h[:add_facts]
          expect(added_facts.count).not_to eq(0)
          transfers = added_facts.select{|triple| triple[1] == 'transfer'}.map{|triple| [triple[0], triple[2]]}
          expect(tubes.map(&:uuid).zip(wells.map(&:uuid))).to eq(transfers)
        end
        it 'does not transfer unrelated tubes' do
          added_facts = instance.process.to_h[:add_facts]
          expect(added_facts.count).not_to eq(0)
          transferred_tubes = added_facts.select{|triple| triple[1] == 'transfer'}.map{|triple| triple[0]}
          expect((unrelated_tubes.map(&:uuid) & transferred_tubes).length).to eq(0)
        end
      end
      it 'transfers the tubes into the wells of the rack by column order' do
        added_facts = instance.process.to_h[:add_facts]
        expect(added_facts.count).not_to eq(0)
        transfers = added_facts.select{|triple| triple[1] == 'transfer'}.map{|triple| [triple[0], triple[2]]}
        expect(tubes.map(&:uuid).zip(wells.map(&:uuid))).to eq(transfers)
      end
      it 'creates inverse properties transfer and transferredFrom' do
        added_facts = instance.process.to_h[:add_facts]
        expect(added_facts.count).not_to eq(0)
        transfers = added_facts.select{|triple| triple[1] == 'transfer'}.map{|triple| [triple[0], triple[2]]}
        transferredFrom = added_facts.select{|triple| triple[1] == 'transferredFrom'}.map{|triple| [triple[2], triple[0]]}
        expect(transferredFrom).to eq(transfers)
      end

      context 'when any of the tubes have an aliquot defined' do
        context 'when some (but not all) of the tubes have an aliquot type' do
          before do
            tubes.first.facts << create(:fact, predicate: 'aliquotType', object: 'DNA')
          end
          it 'produces an error' do
            set_errors = instance.process.to_h[:set_errors]
            expect(set_errors.count).not_to eq(0)
          end
        end

        context 'when all of the tubes have an aliquot type' do
          let(:aliquot_dna) {"DNA"}
          let(:aliquot_rna) { "RNA"}

          before do
            tubes.each do |t|
              t.facts << create(:fact, predicate: 'aliquotType', object: aliquot)
            end
          end
          context 'when there are different aliquots' do
            let(:aliquot) { aliquot_rna }
            before do
              tubes.first.facts << create(:fact, predicate: 'aliquotType', object: aliquot_dna)
            end
            it 'produces an error' do
              set_errors = instance.process.to_h[:set_errors]
              expect(set_errors.count).not_to eq(0)
            end
          end
          context 'when it is DNA' do
            let(:aliquot) { aliquot_dna }
            it 'will set up a DNA Stock plate purpose' do
              added_facts = instance.process.to_h[:add_facts]
              purposes = added_facts.select{|triple| triple[1]=='purpose'}
              expect(purposes.size).to eq(1)
              expect(purposes.first[0]).to eq(rack.uuid)
              expect(purposes.first[2]).to eq("DNA Stock Plate")
            end
          end
          context 'when it is RNA' do
            let(:aliquot) { aliquot_rna }
            it 'will set up an RNA Stock plate purpose' do
              added_facts = instance.process.to_h[:add_facts]
              purposes = added_facts.select{|triple| triple[1]=='purpose'}
              expect(purposes.size).to eq(1)
              expect(purposes.first[0]).to eq(rack.uuid)
              expect(purposes.first[2]).to eq("RNA Stock Plate")
            end
          end
        end
      end


      context 'when some of the tubes were already in the rack' do
        before do
          wells.last.facts << create(:fact, predicate: 'transferredFrom', object_asset_id: tubes.last.id)
        end
        it 'produces an error' do
          set_errors = instance.process.to_h[:set_errors]
          expect(set_errors.count).not_to eq(0)
        end
      end
      context 'when there are other samples already in the rack' do
        before do
          wells.first.facts << create(:fact, predicate: 'transferredFrom', object_asset_id: tubes.first.id)
        end
        it 'starts transferring after the last occupied well of the rack' do
          rest_tubes = tubes.slice(1,tubes.length)
          rest_wells = wells.slice(1,wells.length)
          group.update_attributes(assets: [rest_tubes, rack].flatten)

          added_facts = instance.process.to_h[:add_facts]
          expect(added_facts.count).not_to eq(0)
          transfers = added_facts.select{|triple| triple[1] == 'transfer'}.map{|triple| [triple[0], triple[2]]}
          expect(rest_tubes.map(&:uuid).zip(rest_wells.map(&:uuid))).to eq(transfers)
        end

      end
      context 'when there are no more space left in the rack' do
        let(:tubes) {
          7.times.map{ create(:asset, facts: [create(:fact, predicate: 'a', object: 'Tube')]) }
        }
        it 'produces an error' do
          set_errors = instance.process.to_h[:set_errors]
          expect(set_errors.count).not_to eq(0)
        end
      end
    end
  end
end
