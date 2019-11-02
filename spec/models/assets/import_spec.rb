require 'rails_helper'
require 'remote_assets_helper'

RSpec.describe 'Assets::Import' do
	include RemoteAssetsHelper


  context '#refresh!' do
    let(:asset) { create :asset }
    let(:plate) { build_remote_plate }

    before do
      allow(asset).to receive(:_process_refresh)
      allow(SequencescapeClient).to receive(:find_by_uuid).and_return(true)
    end

    context 'when it is not a remote asset' do
      before do
        allow(asset).to receive(:is_remote_asset?).and_return(false)
      end

      it 'does not refresh' do
        asset.refresh!
        expect(asset).not_to have_received(:_process_refresh)
      end
    end
    context 'when it is a remote asset' do
      before do
        allow(asset).to receive(:is_remote_asset?).and_return(true)
      end
      context 'when the asset has changed' do
        before do
          allow(asset).to receive(:changed_remote?).and_return(true)
        end
        it 'refreshes the asset' do
          asset.refresh!
          expect(asset).to have_received(:_process_refresh)
        end
      end
      context 'when the asset has not changed' do
        before do
          allow(asset).to receive(:changed_remote?).and_return(false)
        end
        it 'refreshes the asset' do
          asset.refresh!
          expect(asset).to have_received(:_process_refresh)
        end
      end
    end
  end
  context '#refresh' do
    let(:asset) { create :asset }
    let(:plate) { build_remote_plate }
    before do
      allow(SequencescapeClient).to receive(:find_by_uuid).and_return(true)
      allow(asset).to receive(:changed_remote?).and_return(false)
    end
    it 'recognises a plate' do
      asset.facts << create(:fact, predicate: 'a', object: 'TubeRack', is_remote?: true)
      asset.refresh
      expect(SequencescapeClient).to have_received(:find_by_uuid).with(asset.uuid)
    end
    it 'recognises a tube' do
      asset.facts << create(:fact, predicate: 'a', object: 'Tube', is_remote?: true)
      asset.refresh
      expect(SequencescapeClient).to have_received(:find_by_uuid).with(asset.uuid)
    end
    context 'when actually updating' do
      before do
        allow(SequencescapeClient).to receive(:find_by_uuid).and_return(plate)
        allow(asset).to receive(:changed_remote?).and_return(true)
      end
      it 'does not destroy remote facts that have not changed' do
        fact = create(:fact, predicate: 'a', object: 'Plate', is_remote?: true)
        asset.facts << fact
        asset.refresh
        expect{fact.reload}.not_to raise_error
        expect(asset.facts.with_predicate('a').first.object).to eq('Plate')
      end
      it 'destroys and refreshes remote facts that have changed' do
        fact = create(:fact, predicate: 'a', object: 'Tube', is_remote?: true)
        asset.facts << fact
        asset.refresh
        expect{fact.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect(asset.facts.with_predicate('a').first.object).to eq('Plate')
      end
      it 'does not destroy local facts' do
        fact = create(:fact, predicate: 'is', object: 'Red', is_remote?: false)
        asset.facts << fact
        asset.refresh
        expect{fact.reload}.not_to raise_error
        expect(asset.facts.with_predicate('is').first.object).to eq('Red')
      end
      it 'does not destroy the assets linked by remote facts' do
        asset2 = create(:asset)
        fact = create(:fact, predicate: 'contains', object_asset_id: asset2.id, is_remote?: true)
        asset.facts << fact
        asset.refresh
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
        asset.refresh
        expect{fact_well.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect{asset2.reload}.not_to raise_error
      end

      it 'replaces the remote facts of the assets linked with remote facts that are changing' do
        asset2 = create(:asset, uuid: plate.wells.first.uuid)
        fact_well = create(:fact, predicate: 'location', object: 'A01', is_remote?: true)
        asset2.facts << fact_well
        fact = create(:fact, predicate: 'contains', object_asset_id: asset2.id, is_remote?: true)
        asset.facts << fact
        asset.refresh
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
  		setup do
  			@barcode_plate = "1"
  			@asset = Asset.create!(barcode: @barcode_plate)
  		end
  		it 'should return the local asset when looking by its barcode' do
  			expect(Asset.find_or_import_asset_with_barcode(@barcode_plate)).to eq(@asset)
  		end
  		it 'should return the local asset when looking by its barcode' do
  			expect(Asset.find_or_import_asset_with_barcode(@asset.uuid)).to eq(@asset)
  		end
  	end
  	context 'when importing a remote asset' do
      let(:SequencescapeClient) { double('sequencescape_client') }

			setup do

        @remote_plate_asset = build_remote_plate(barcode: '2')
        @barcode_plate = @remote_plate_asset.barcode
        stub_client_with_asset(SequencescapeClient, @remote_plate_asset)
			end

      context 'when the asset is a tube' do
        setup do
          @remote_tube_asset = build_remote_tube(barcode: '1')
          stub_client_with_asset(SequencescapeClient, @remote_tube_asset)
        end
        it 'should try to obtain a tube' do
          @asset = Asset.find_or_import_asset_with_barcode(@remote_tube_asset.barcode)
          expect(SequencescapeClient).to have_received(:find_by_uuid).with(@remote_tube_asset.uuid)
        end
      end

      context 'when the asset is a plate' do
        setup do
          @remote_plate_asset = build_remote_plate(barcode: '2')
          stub_client_with_asset(SequencescapeClient, @remote_plate_asset)
        end
        it 'should try to obtain a plate' do
          @asset = Asset.find_or_import_asset_with_barcode(@remote_plate_asset.barcode)
          expect(SequencescapeClient).to have_received(:find_by_uuid).with(@remote_plate_asset.uuid)
        end

        context 'when the supplier sample name has not been provided to some samples' do
          context 'when the asset is a plate' do
            setup do
              wells = [
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
              @remote_plate_asset_without_supplier = build_remote_plate(barcode: '5', wells: wells)
              stub_client_with_asset(SequencescapeClient, @remote_plate_asset_without_supplier)
            end
            it 'imports the information of the wells that have a supplier name' do
              @asset = Asset.find_or_import_asset_with_barcode(@remote_plate_asset_without_supplier.barcode)
              wells = @asset.facts.with_predicate('contains').map(&:object_asset)
              wells_with_info = wells.select{|w| w.facts.where(predicate: 'supplier_sample_name').count > 0}
              locations_with_info = wells_with_info.map{|w| w.facts.with_predicate('location').first.object}
              expect(locations_with_info).to eq(['C1','D1'])
            end
          end
          context 'when the asset is a tube' do
            context 'when the supplier name has not been provided' do
              setup do
                @remote_tube_asset_without_supplier = build_remote_tube(barcode: '5', aliquots: [
                  build_remote_aliquot(sample: build_remote_sample(sample_metadata:
                    double('sample_metadata', supplier_name: nil, sample_common_name: 'species')))
                ])
                stub_client_with_asset(SequencescapeClient, @remote_tube_asset_without_supplier)
              end

              it 'imports the information of the tube but does not set any supplier name' do
                @asset = Asset.find_or_import_asset_with_barcode(@remote_tube_asset_without_supplier.barcode)
                @asset.facts.reload
                expect(@asset.facts.with_predicate('supplier_sample_name').count).to eq(0)
              end
            end
            context 'when the supplier name has been provided' do
              setup do
                @remote_tube_asset_with_supplier = build_remote_tube(barcode: '5')
                stub_client_with_asset(SequencescapeClient, @remote_tube_asset_with_supplier)
              end

              it 'imports the supplier name' do
                @asset = Asset.find_or_import_asset_with_barcode(@remote_tube_asset_with_supplier.barcode)
                expect(@asset.facts.with_predicate('supplier_sample_name').count).to eq(1)
              end

              it 'imports the common name' do
                @asset = Asset.find_or_import_asset_with_barcode(@remote_tube_asset_with_supplier.barcode)
                expect(@asset.facts.with_predicate('sample_common_name').count).to eq(1)
              end
            end

          end
        end

        context 'when the plate does not have aliquots in its wells' do
          setup do
            wells = ['A1','B1'].map {|l| build_remote_well(l, aliquots: []) }
            @remote_plate_asset_without_aliquots = build_remote_plate(barcode: '3', wells: wells)
            stub_client_with_asset(SequencescapeClient, @remote_plate_asset_without_aliquots)
          end
          it 'creates the wells with the same uuid as in the remote asset' do
            @asset = Asset.find_or_import_asset_with_barcode(@remote_plate_asset_without_aliquots.barcode)
            wells = @asset.facts.with_predicate('contains').map(&:object_asset)
            expect(wells.zip(@remote_plate_asset_without_aliquots.wells).all?{|w,w2| w.uuid == w2.uuid}).to eq(true)
          end
        end
        context 'when the plate does not have samples in its wells' do
          setup do
            wells = ['A1','B1'].map {|l| build_remote_well(l, aliquots: [build_remote_aliquot(sample: nil)]) }
            @remote_plate_asset_without_samples = build_remote_plate(barcode: '4', wells: wells)
            stub_client_with_asset(SequencescapeClient, @remote_plate_asset_without_samples)
          end
          it 'creates the wells with the same uuid as in the remote asset' do
            @asset = Asset.find_or_import_asset_with_barcode(@remote_plate_asset_without_samples.barcode)
            wells = @asset.facts.with_predicate('contains').map(&:object_asset)
            expect(wells.zip(@remote_plate_asset_without_samples.wells).all?{|w,w2| w.uuid == w2.uuid}).to eq(true)
          end
        end
      end

			it 'should create the corresponding facts from the json' do
				@asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
				@asset.facts.reload
        predicates = ["a", "pushTo", "purpose", "is", "contains", "contains", "study_name", "study_uuid"]
        expect(predicates.all? do |predicate|
          @asset.facts.where(predicate: predicate).count > 0
        end).to eq(true)
			end

      it 'should store the study uuid in a safe format' do
        @asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
        study_uuid = @remote_plate_asset.wells.first.aliquots.first.study.uuid
        @asset.facts.reload
        asset_study_uuid = @asset.facts.where(predicate: 'study_uuid').first.object
        expect(asset_study_uuid).to eq(TokenUtil.quote(study_uuid))
      end

		  context 'for the first time' do
		  	it 'should create the local asset' do
		  		expect(Asset.count).to eq(0)
		  		Asset.find_or_import_asset_with_barcode(@barcode_plate)
		  		expect(Asset.count>0).to eq(true)
		  	end
		  end
		  context 'when is already imported' do
        context 'when the remote source is not present anymore' do
          setup do
            @asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
            allow(SequencescapeClient).to receive(:find_by_uuid).and_return(nil)
          end
          it 'should raise an exception' do
            expect{Asset.find_or_import_asset_with_barcode(@barcode_plate)}.to raise_exception Assets::Import::RefreshSourceNotFoundAnymore
          end
        end
        context 'when the remote source is present' do
  		  	setup do
  		  		@asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  	end
  		  	it 'should not create a new local asset' do
  		  		count = Asset.count
  					Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  		expect(Asset.count).to eq(count)
  		  	end

  		  	context 'when the local copy is up to date' do
  		  		it 'should not destroy any remote facts' do
  		  			remote_facts = @asset.facts.from_remote_asset
  		  			remote_facts.each(&:reload)
  		  			Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  			expect{remote_facts.each(&:reload)}.not_to raise_error
  		  		end
  		  	end

  		  	context 'when the local copy is out of date' do
  		  		before do
  		  			@asset.update_attributes(remote_digest: 'RANDOM')
              @fact_changed = @asset.facts.from_remote_asset.where(predicate: 'contains').first

              @well_changed = create :asset
              @dependant_fact = create :fact, predicate: 'some', object: 'Moredata', is_remote?: true
              @well_changed.facts << @dependant_fact
              @fact_changed.update_attributes(object_asset_id: @well_changed.id)
  		  		end
  		  		it 'should destroy any remote facts that has changed' do
  		  			Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  			expect{@fact_changed.reload}.to raise_exception ActiveRecord::RecordNotFound
  		  		end

            it 'should destroy any contains dependant remote facts' do
              Asset.find_or_import_asset_with_barcode(@barcode_plate)
              expect{@dependant_fact.reload}.to raise_exception ActiveRecord::RecordNotFound
            end

  		  		it 'should re-create new remote facts' do
  		  			@asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  			@asset.facts.reload
              expect(@asset.facts.from_remote_asset.all?{|f| f.object_asset != @well_changed})
  		  		end
  		  	end
        end
		  end
  	end
  end
end
