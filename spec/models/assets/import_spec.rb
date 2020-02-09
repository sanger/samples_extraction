require 'rails_helper'
require 'remote_assets_helper'

RSpec.describe 'Assets::Import' do
	include RemoteAssetsHelper


  context '#refresh' do
    let(:asset) { create :asset, uuid: uuid, remote_digest: digest }
    let(:plate) { build_remote_plate }
    before do
      stub_client_with_asset(SequencescapeClient, plate)
    end

    context 'when it is not a remote asset' do
      let(:uuid) { SecureRandom.uuid }
      let(:digest) { nil }
      it 'does not refresh' do
        allow(SequencescapeClient).to receive(:find_by_uuid)
        allow(SequencescapeClient).to receive(:get_remote_asset)
        asset.refresh
        expect(SequencescapeClient).not_to have_received(:find_by_uuid)
        expect(SequencescapeClient).not_to have_received(:get_remote_asset)
      end
    end
    context 'when it is a remote asset' do
      let(:uuid) { plate.uuid }
      let(:digest) { 'initial_digest' }

      context 'when the asset has changed' do
        it 'refreshes the asset' do
          allow(SequencescapeClient).to receive(:find_by_uuid).and_return(plate)
          allow(SequencescapeClient).to receive(:get_remote_asset)
          asset.refresh
          expect(SequencescapeClient).to have_received(:find_by_uuid)
        end
      end
    end
  end
  context '#refresh!' do
    let(:digest) { 'initial_digest' }
    let(:asset) { create :asset, uuid: plate.uuid, remote_digest: digest }
    let(:plate) { build_remote_plate }
    before do
      stub_client_with_asset(SequencescapeClient, plate)
    end

    it 'updates the asset' do
      asset.facts << create(:fact, predicate: 'a', object: 'TubeRack', is_remote?: true)
      expect{asset.refresh!}.to change{asset.facts.count}
    end

    context 'when actually updating' do
      it 'does not destroy remote facts that have not changed' do
        fact = create(:fact, predicate: 'a', object: 'Plate', is_remote?: true)
        asset.facts << fact
        asset.refresh!
        expect{fact.reload}.not_to raise_error
        expect(asset.facts.with_predicate('a').first.object).to eq('Plate')
      end
      it 'destroys and refreshes remote facts that have changed' do
        fact = create(:fact, predicate: 'a', object: 'Tube', is_remote?: true)
        asset.facts << fact
        asset.refresh!
        expect{fact.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect(asset.facts.with_predicate('a').first.object).to eq('Plate')
      end
      it 'does not destroy local facts' do
        fact = create(:fact, predicate: 'color', object: 'Red', is_remote?: false)
        asset.facts << fact
        asset.refresh!
        expect{fact.reload}.not_to raise_error
        expect(asset.facts.with_predicate('color').first.object).to eq('Red')
      end
      it 'does not destroy the assets linked by remote facts' do
        asset2 = create(:asset)
        fact = create(:fact, predicate: 'contains', object_asset_id: asset2.id, is_remote?: true)
        asset.facts << fact
        asset.refresh!
        expect{fact.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect{asset.reload}.not_to raise_error
        expect{asset2.reload}.not_to raise_error
      end
      it 'replaces the local facts of the assets linked with remote facts that are changing' do
        asset2 = create(:asset, uuid: plate.wells.first.uuid)
        fact_well = create(:fact, predicate: 'location', object: 'A01', is_remote?: false)
        asset2.facts << fact_well
        fact = create(:fact, predicate: 'contains', object_asset_id: asset2.id, is_remote?: true)
        asset.facts << fact
        asset.refresh!
        expect{fact_well.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect{asset2.reload}.not_to raise_error
      end

      it 'replaces the remote facts of the assets linked with remote facts that are changing' do
        asset2 = create(:asset, uuid: plate.wells.first.uuid)
        fact_well = create(:fact, predicate: 'location', object: 'A01', is_remote?: true)
        asset2.facts << fact_well
        fact = create(:fact, predicate: 'contains', object_asset_id: asset2.id, is_remote?: true)
        asset.facts << fact
        asset.refresh!
        expect{fact_well.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect{asset2.reload}.not_to raise_error
      end
    end
  end

  context '#find_or_import_asset_with_barcode' do
  	context 'when importing an asset that does not exist' do
  		setup do
  			allow(SequencescapeClient).to receive(:get_remote_asset).and_return(nil)
  		end
  		it 'should return nil' do
  			expect(Asset.find_or_import_asset_with_barcode('NOT_FOUND')).to eq(nil)
  		end
      it 'should not create a new asset' do
        expect(Asset.all.count).to eq(0)
        Asset.find_or_import_asset_with_barcode('NOT_FOUND')
        expect(Asset.all.count).to eq(0)
      end
  	end
  	context 'when importing a local asset' do
      let(:barcode) { generate :barcode }
      let!(:asset) { create(:asset, barcode: barcode) }
  		before do
        allow(SequencescapeClient).to receive(:get_remote_asset).and_return(nil)
  		end
  		it 'should return the local asset when looking by its barcode' do
  			expect(Asset.find_or_import_asset_with_barcode(barcode)).to eq(asset)
  		end
  		it 'should return the local asset when looking by its barcode' do
  			expect(Asset.find_or_import_asset_with_barcode(asset.uuid)).to eq(asset)
  		end
  	end
  	context 'when importing a remote asset' do
      let(:plate_barcode) { generate :plate_barcode }
      let(:remote_plate_asset) { build_remote_plate(barcode: plate_barcode) }
      before do
        stub_client_with_asset(SequencescapeClient, remote_plate_asset)
      end

      it 'should create the corresponding facts from the json' do
        asset = Asset.find_or_import_asset_with_barcode(plate_barcode)
        asset.facts.reload
        predicates = ["a", "pushTo", "purpose", "is", "contains", "contains", "study_name", "study_uuid"]
        expect(predicates.all? do |predicate|
          asset.facts.where(predicate: predicate).count > 0
        end).to eq(true)
      end

      it 'should store the study uuid in a safe format' do
        asset = Asset.find_or_import_asset_with_barcode(plate_barcode)
        study_uuid = remote_plate_asset.wells.first.aliquots.first.study.uuid
        asset.facts.reload
        asset_study_uuid = asset.facts.where(predicate: 'study_uuid').first.object
        expect(asset_study_uuid).to eq(TokenUtil.quote(study_uuid))
      end

      context 'for the first time' do
        it 'should create the local asset' do
          expect{
            Asset.find_or_import_asset_with_barcode(plate_barcode)
          }.to change{Asset.count}.from(0)
        end
      end
      context 'when is already imported' do
        let(:up_to_date_remote_digest) {
          Importers::Concerns::Annotator.digest_for_remote_asset(remote_plate_asset)
        }
        let(:remote_digest) { up_to_date_remote_digest }
        let!(:asset) { create(:asset,
          barcode: plate_barcode,
          uuid: remote_plate_asset.uuid, remote_digest: up_to_date_remote_digest)}
        context 'when the remote source is not present anymore' do
          before do
            allow(SequencescapeClient).to receive(:find_by_uuid).and_return(nil)
          end
          it 'should raise an exception' do
            expect{
              Asset.find_or_import_asset_with_barcode(plate_barcode)
            }.to raise_exception Assets::Import::RefreshSourceNotFoundAnymore
          end
        end
        context 'when the remote source is present' do
          it 'returns the local asset but updated' do
            asset2 = Asset.find_or_import_asset_with_barcode(plate_barcode)
            asset.reload
            expect(asset.id).to eq(asset2.id)
            #expect(asset2.remote_digest != asset.remote_digest).to eq(true)
          end

          context 'when the local copy is up to date' do
            it 'should not destroy any remote facts' do
              remote_facts = asset.facts.from_remote_asset
              remote_facts.each(&:reload)
              Asset.find_or_import_asset_with_barcode(plate_barcode)
              expect{remote_facts.each(&:reload)}.not_to raise_error
            end
          end

          context 'when the local copy is out of date' do
            let!(:asset) { Asset.find_or_import_asset_with_barcode(plate_barcode) }
            let!(:out_of_date_remote_digest) { 'out of date' }
            let!(:remote_digest) { out_of_date_remote_digest }
            before do
              asset.update_attributes(remote_digest: remote_digest)
            end
            context 'when we have some changes' do
              let!(:well_not_existing_anymore) { create :asset}
              let!(:fact_from_changed_well) { asset.facts.from_remote_asset.where(predicate: 'contains').first }
              let!(:changed_well) { fact_from_changed_well.object_asset }
              let!(:fact_added_to_changed_well) {
                create :fact, predicate: 'some', object: 'Moredata', is_remote?: true, literal: true
              }
              let!(:fact_from_unexisting_well) {
                create(:fact, predicate: 'contains', object_asset: well_not_existing_anymore, is_remote?: true, literal: false)
              }
              before do
                asset.facts << fact_from_unexisting_well
                changed_well.facts << fact_added_to_changed_well
              end
              it 'should destroy any remote facts that has changed' do
                Asset.find_or_import_asset_with_barcode(plate_barcode)
                expect{fact_from_unexisting_well.reload}.to raise_exception ActiveRecord::RecordNotFound
              end

              it 'should destroy any contains dependant remote facts' do
                Asset.find_or_import_asset_with_barcode(plate_barcode)
                expect{fact_added_to_changed_well.reload}.to raise_exception ActiveRecord::RecordNotFound
              end

              it 'should re-create new remote facts' do
                @asset = Asset.find_or_import_asset_with_barcode(plate_barcode)
                @asset.facts.reload
                expect(asset.facts.from_remote_asset.all?{|f| f.object_asset != changed_well})
              end
            end
          end
        end
      end

      context 'when the asset is a tube' do
        let(:tube_barcode) { generate :tube_barcode }
        let(:remote_tube_asset) { build_remote_tube(barcode: tube_barcode) }
        before do
          stub_client_with_asset(SequencescapeClient, remote_tube_asset)
        end
        it 'should try to obtain a tube' do
          Asset.find_or_import_asset_with_barcode(tube_barcode)
          expect(SequencescapeClient).to have_received(:get_remote_asset).with([tube_barcode],[])
        end
        context 'when the supplier name has not been provided' do
          let(:tube_barcode_without_supplier) { generate :tube_barcode }
          let(:remote_tube_asset_without_supplier) {
            build_remote_tube(barcode: tube_barcode_without_supplier, aliquots: [
              build_remote_aliquot(sample: build_remote_sample(sample_metadata:
                double('sample_metadata', supplier_name: nil, sample_common_name: 'species')))
            ])
          }
          before do
            stub_client_with_asset(SequencescapeClient, remote_tube_asset_without_supplier)
          end

          it 'imports the information of the tube but does not set any supplier name' do
            asset = Asset.find_or_import_asset_with_barcode(tube_barcode_without_supplier)
            asset.facts.reload
            expect(asset.facts.with_predicate('supplier_sample_name').count).to eq(0)
          end
        end
        context 'when the supplier name has been provided' do
          let(:tube_barcode_with_supplier) { generate :tube_barcode }
          let(:remote_tube_asset_with_supplier) { build_remote_tube(barcode: tube_barcode_with_supplier) }
          before do
            stub_client_with_asset(SequencescapeClient, remote_tube_asset_with_supplier)
          end

          it 'imports the supplier name' do
            asset = Asset.find_or_import_asset_with_barcode(tube_barcode_with_supplier)
            expect(asset.facts.with_predicate('supplier_sample_name').count).to eq(1)
          end

          it 'imports the common name' do
            asset = Asset.find_or_import_asset_with_barcode(tube_barcode_with_supplier)
            expect(asset.facts.with_predicate('sample_common_name').count).to eq(1)
          end
        end
      end

      context 'when the asset is a plate' do
        let(:plate_barcode) { generate :plate_barcode }
        let(:remote_plate_asset) { build_remote_plate(barcode: plate_barcode) }
        before do
          stub_client_with_asset(SequencescapeClient, remote_plate_asset)
        end
        it 'should try to obtain a plate' do
          @asset = Asset.find_or_import_asset_with_barcode(plate_barcode)
          expect(SequencescapeClient).to have_received(:get_remote_asset).with([plate_barcode],[])
        end

        context 'when the plate does not have aliquots in its wells' do
          let(:wells) { ['A1','B1'].map {|l| build_remote_well(l, aliquots: []) } }
          let(:plate_barcode_without_aliquots) { generate :plate_barcode }
          let(:remote_plate_asset_without_aliquots) {
            build_remote_plate(barcode: plate_barcode_without_aliquots, wells: wells)
          }
          before do
            stub_client_with_asset(SequencescapeClient, remote_plate_asset_without_aliquots)
          end
          it 'creates the wells with the same uuid as in the remote asset' do
            asset = Asset.find_or_import_asset_with_barcode(plate_barcode_without_aliquots)
            wells = asset.facts.with_predicate('contains').map(&:object_asset)
            expect(wells.zip(remote_plate_asset_without_aliquots.wells).all?{|w,w2| w.uuid == w2.uuid}).to eq(true)
          end
        end
        context 'when the plate does not have samples in its wells' do
          let(:wells) {
            ['A1','B1'].map {|l| build_remote_well(l, aliquots: [build_remote_aliquot(sample: nil)]) }
          }
          let(:plate_barcode_without_samples) { generate :plate_barcode }
          let(:remote_plate_asset_without_samples) {
            build_remote_plate(barcode: plate_barcode_without_samples, wells: wells)
          }
          before do
            stub_client_with_asset(SequencescapeClient, remote_plate_asset_without_samples)
          end
          it 'creates the wells with the same uuid as in the remote asset' do
            asset = Asset.find_or_import_asset_with_barcode(plate_barcode_without_samples)
            wells = asset.facts.with_predicate('contains').map(&:object_asset)
            expect(wells.zip(remote_plate_asset_without_samples.wells).all? do |w,w2|
              w.uuid == w2.uuid
            end).to eq(true)
          end
        end

        context 'when the supplier sample name has not been provided to some samples' do
          let(:plate_barcode_without_supplier) { generate :plate_barcode}
          let(:remote_plate_asset_without_supplier) {
            build_remote_plate(barcode: plate_barcode_without_supplier, wells: wells)
          }
          let(:wells) {
            [
              build_remote_well('A1', aliquots: [build_remote_aliquot(sample:
                build_remote_sample(sample_metadata: nil))]),
              build_remote_well('B1', aliquots: [build_remote_aliquot(sample:
                build_remote_sample(sample_metadata: double('sample_metadata',
                  sample_common_name: 'species', supplier_name: nil)))]),
              build_remote_well('C1', aliquots: [build_remote_aliquot(sample:
                build_remote_sample(sample_metadata: double('sample_metadata',
                  sample_common_name: 'species', supplier_name: 'a supplier name')))]),
              build_remote_well('D1', aliquots: [build_remote_aliquot(sample:
                build_remote_sample(sample_metadata: double('sample_metadata',
                  sample_common_name: 'species', supplier_name: 'a supplier name')))])
            ]
          }

          before do
            stub_client_with_asset(SequencescapeClient, remote_plate_asset_without_supplier)
          end
          it 'imports the information of the wells that have a supplier name' do
            asset = Asset.find_or_import_asset_with_barcode(plate_barcode_without_supplier)
            wells = asset.facts.with_predicate('contains').map(&:object_asset)
            wells_with_info = wells.select{|w| w.facts.where(predicate: 'supplier_sample_name').count > 0}
            locations_with_info = wells_with_info.map{|w| w.facts.with_predicate('location').first.object}
            expect(locations_with_info).to eq(['C1','D1'])
          end
        end
      end
  	end
  end
end
