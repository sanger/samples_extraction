require 'rails_helper'
RSpec.describe Asset do
  context 'SCOPE ::from_remote_service' do
    it 'filters to select only remote assets that are up to date with Sequencescape' do
      seq1 = create(:plate, remote_digest: '1')
      seq2 = create(:plate)
      seq3 = create(:plate, remote_digest: '2')
      expect(Asset.from_remote_service).to eq([seq1, seq3])
    end
  end
  context '#has_wells?' do
    it 'returns true when it is a plate with wells' do
      plate = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Plate')
      well = create(:asset)
      plate.facts << create(:fact, predicate: 'contains', object_asset: well)
      expect(plate.has_wells?).to eq(true)
    end
    it 'returns false when it is an empty plate' do
      plate = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Plate')
      well = create(:asset)
      expect(plate.has_wells?).to eq(false)
    end
    it 'returns false when it is something else' do
      plate = create(:asset)
      something_else = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Bottle')
      well = create(:asset)
      plate.facts << create(:fact, predicate: 'contains', object_asset: well)
      expect(plate.has_wells?).to eq(false)
      something_else = create(:asset)
      expect(something_else.has_wells?).to eq(false)
    end
  end

  context '#study_name' do
    let(:study) { 'A STUDY'}
    context 'if it is a tube' do
      it 'returns the study name of the tube' do
        tube = create :asset
        tube.facts << create(:fact, predicate: 'a', object: 'Tube')
        tube.facts << create(:fact, predicate: 'study_name', object: study)
        expect(tube.study_name).to eq(study)
      end
    end
    context 'if it is a plate' do
      context 'if the plate has a study name property' do
        it 'returns the study name of the tube' do
          plate = create :asset
          plate.facts << create(:fact, predicate: 'a', object: 'Plate')
          plate.facts << create(:fact, predicate: 'study_name', object: study)
          expect(plate.study_name).to eq(study)
        end
      end
      context 'if the plate do not have study name' do
        context 'when the plate has tubes' do
          context 'when the tube does not have a study name' do
            it 'returns empty string' do
              tube = create :asset
              tube.facts << create(:fact, predicate: 'a', object: 'Tube')
              plate = create :asset
              plate.facts << create(:fact, predicate: 'a', object: 'Plate')
              plate.facts << create(:fact, predicate: 'contains', object_asset: tube)
              expect(plate.study_name).to eq('')
            end
          end

          context 'when the tubes have a study name' do
            it 'returns the study name of the first tube' do
              tube = create :asset
              tube.facts << create(:fact, predicate: 'a', object: 'Tube')
              tube.facts << create(:fact, predicate: 'study_name', object: study)

              plate = create :asset
              plate.facts << create(:fact, predicate: 'a', object: 'Plate')
              plate.facts << create(:fact, predicate: 'contains', object_asset: tube)
              expect(plate.study_name).to eq(study)
            end
          end
        end
      end
    end
  end
end
