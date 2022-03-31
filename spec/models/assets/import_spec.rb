require 'rails_helper'
require 'remote_assets_helper'

RSpec.describe 'Assets::Import' do
  include RemoteAssetsHelper

  context '#refresh!' do
    let(:asset) { create :asset }
    let(:plate) { build_remote_v2_plate }

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
    let(:plate) { build_remote_v2_plate }

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
        expect { fact.reload }.not_to raise_error
        expect(asset.facts.with_predicate('a').first.object).to eq('Plate')
      end

      it 'destroys and refreshes remote facts that have changed' do
        fact = create(:fact, predicate: 'a', object: 'Tube', is_remote?: true)
        asset.facts << fact
        asset.refresh
        expect { fact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(asset.facts.with_predicate('a').first.object).to eq('Plate')
      end

      it 'does not destroy local facts' do
        fact = create(:fact, predicate: 'is', object: 'Red', is_remote?: false)
        asset.facts << fact
        asset.refresh
        expect { fact.reload }.not_to raise_error
        expect(asset.facts.with_predicate('is').first.object).to eq('Red')
      end

      it 'does not destroy the assets linked by remote facts' do
        asset2 = create(:asset)
        fact = create(:fact, predicate: 'contains', object_asset_id: asset2.id, is_remote?: true)
        asset.facts << fact
        asset.refresh
        expect { fact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { asset.reload }.not_to raise_error
        expect { asset2.reload }.not_to raise_error
      end

      it 'replaces the local facts of the assets linked with remote facts that are changing' do
        asset2 = create(:asset, uuid: plate.wells.first.uuid)
        fact_well = create(:fact, predicate: 'location', object: 'A01', is_remote?: false)
        asset2.facts << fact_well
        fact = create(:fact, predicate: 'contains', object_asset_id: asset2.id, is_remote?: true)
        asset.facts << fact
        asset.refresh
        expect { fact_well.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { asset2.reload }.not_to raise_error
      end

      it 'replaces the remote facts of the assets linked with remote facts that are changing' do
        asset2 = create(:asset, uuid: plate.wells.first.uuid)
        fact_well = create(:fact, predicate: 'location', object: 'A01', is_remote?: true)
        asset2.facts << fact_well
        fact = create(:fact, predicate: 'contains', object_asset_id: asset2.id, is_remote?: true)
        asset.facts << fact
        asset.refresh
        expect { fact_well.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { asset2.reload }.not_to raise_error
      end
    end
  end

  shared_examples 'a plate or tube rack' do
    it 'should create the corresponding facts from the json' do
      facts = the_method.facts.reload
      predicates = ["a", "pushTo", "purpose", "is", "contains", "contains", "study_name", "study_uuid"]
      predicate_facts = predicates.map { |predicate| facts.with_predicate(predicate) }
      expect(predicate_facts).to all be_present
    end

    it 'should store the study uuid in a safe format' do
      asset_study_uuid = the_method.facts.reload.with_predicate('study_uuid').first.object
      expect(asset_study_uuid).to eq(TokenUtil.quote(expected_study_uuid))
    end

    context 'for the first time' do
      it 'should create the local asset' do
        expect { the_method }.to change(Asset, :count).by(created_assets)
      end
    end

    context 'when is already imported' do
      let!(:original_import) { Asset.find_or_import_asset_with_barcode(barcode) }

      context 'when the remote source is not present anymore' do
        setup do
          allow(SequencescapeClient).to receive(:find_by_uuid).and_return(nil)
        end

        it 'should raise an exception' do
          expect { the_method }.to raise_exception Assets::Import::RefreshSourceNotFoundAnymore
        end
      end

      context 'when the remote source is present' do
        it 'should not create a new local asset' do
          expect { the_method }.not_to change(Asset, :count)
        end

        context 'when the local copy is up to date' do
          it 'should not destroy any remote facts' do
            remote_facts = the_method.facts.from_remote_asset
            remote_facts.each(&:reload)
            the_method
            expect { remote_facts.each(&:reload) }.not_to raise_error
          end
        end

        context 'when the local copy is out of date' do
          before do
            original_import.update_attributes(remote_digest: 'RANDOM')
            @fact_changed = original_import.facts.from_remote_asset.where(predicate: 'contains').first

            @well_changed = create :asset
            @dependant_fact = create :fact, predicate: 'some', object: 'Moredata', is_remote?: true
            @well_changed.facts << @dependant_fact
            @fact_changed.update_attributes(object_asset_id: @well_changed.id)
          end

          it 'should destroy any remote facts that has changed' do
            the_method
            expect { @fact_changed.reload }.to raise_exception ActiveRecord::RecordNotFound
          end

          it 'should destroy any contains dependant remote facts' do
            the_method
            expect { @dependant_fact.reload }.to raise_exception ActiveRecord::RecordNotFound
          end

          it 'should re-create new remote facts' do
            expect(the_method.facts.from_remote_asset.all? { |f| f.object_asset != @well_changed })
          end
        end
      end
    end
  end

  shared_examples 'a partial import of samples' do
    it 'imports the information of the tubes that have a supplier name' do
      tubes = subject.facts.with_predicate('contains').map(&:object_asset)
      tubes_with_info = tubes.select { |t| t.facts.with_predicate('supplier_sample_name').present? }
      locations_with_info = tubes_with_info.map { |t| t.facts.with_predicate('location').first.object }

      expect(locations_with_info).to eq(['C1', 'D1'])
    end
  end

  describe '#find_or_import_asset_with_barcode' do
    subject(:the_method) { Asset.find_or_import_asset_with_barcode(barcode) }

    context 'when importing an asset that does not exist' do
      let(:barcode) { 'NOT FOUND' }

      setup do
        allow(SequencescapeClient).to receive(:find_by_barcode).and_return(nil)
      end

      it { is_expected.to be_nil }

      it 'should not create a new asset' do
        expect { the_method }.not_to change(Asset, :count)
      end
    end

    context 'when importing a local asset via its barcode' do
      let(:barcode) { generate(:barcode) }
      let!(:local_asset) { Asset.create!(barcode: barcode) }

      it { is_expected.to eq local_asset }
    end

    context 'when importing a local asset via its uuid' do
      # @todo This behaviour is a bit unexpected for a method called #find_or_import_asset_with_barcode.
      #       We should either explicitly look up by UUID where required, or have a separate method to
      #       handle the ambiguity
      let(:barcode) { local_asset.uuid }
      let!(:local_asset) { Asset.create!(barcode: generate(:barcode)) }

      it { is_expected.to eq local_asset }
    end

    context 'when importing a remote asset' do
      let(:barcode) { remote_asset.barcode }

      setup do
        stub_client_with_asset(SequencescapeClient, remote_asset)
      end

      context 'when the asset is a tube' do
        context 'when the supplier name has not been provided' do
          let(:remote_asset) do
            sample_no_supplier_name = build_remote_sample(
              sample_metadata: double('sample_metadata',
                                      supplier_name: nil,
                                      sample_common_name: 'species')
            )
            build_remote_tube(
              barcode: generate(:barcode),
              aliquots: [build_remote_aliquot(sample: sample_no_supplier_name)]
            )
          end

          it 'imports the information of the tube but does not set any supplier name' do
            expect(the_method.facts.reload.with_predicate('supplier_sample_name')).to be_empty
          end
        end

        context 'when the supplier name has been provided' do
          let(:remote_asset) { build_remote_tube(barcode: generate(:barcode)) }

          it 'imports the supplier name' do
            expect(the_method.facts.reload.with_predicate('supplier_sample_name')).to be_one
          end

          it 'imports the common name' do
            expect(the_method.facts.reload.with_predicate('sample_common_name')).to be_one
          end
        end
      end

      context 'when the asset is a plate with complete information' do
        let(:remote_asset) { build_remote_v2_plate(barcode: generate(:barcode)) }
        let(:expected_study_uuid) { remote_asset.wells.first.aliquots.first.study.uuid }
        let(:created_assets) { 3 }

        it_behaves_like 'a plate or tube rack'
      end

      context 'when the supplier sample name has not been provided to some samples' do
        let(:remote_asset) do
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
          build_remote_v2_plate(barcode: generate(:barcode), wells: wells)
        end

        it_behaves_like 'a partial import of samples'
      end

      context 'when the plate does not have aliquots in its wells' do
        let(:remote_asset) do
          wells = ['A1', 'B1'].map { |l| build_remote_well(l, aliquots: []) }
          build_remote_v2_plate(barcode: generate(:barcode), wells: wells)
        end

        it 'creates the wells with the same uuid as in the remote asset' do
          wells = the_method.facts.with_predicate('contains').map(&:object_asset)
          expect(wells.zip(remote_asset.wells).all? { |w, w2| w.uuid == w2.uuid }).to eq(true)
        end
      end

      context 'when the plate does not have samples in its wells' do
        let(:remote_asset) do
          wells = ['A1', 'B1'].map { |l| build_remote_well(l, aliquots: [build_remote_aliquot(sample: nil)]) }
          build_remote_v2_plate(barcode: generate(:barcode), wells: wells)
        end

        it 'creates the wells with the same uuid as in the remote asset' do
          wells = the_method.facts.with_predicate('contains').map(&:object_asset)
          expect(wells.zip(remote_asset.wells).all? { |w, w2| w.uuid == w2.uuid }).to eq(true)
        end
      end

      context 'when the asset is a tube rack' do
        let(:remote_asset) { build_remote_tube_rack(barcode: generate(:barcode)) }
        let(:expected_study_uuid) { remote_asset.racked_tubes.first.tube.aliquots.first.study.uuid }
        let(:created_assets) { 3 }

        it_behaves_like 'a plate or tube rack'

        context 'when the supplier sample name has not been provided to some samples' do
          let(:remote_asset) do
            racked_tubes = [
              build_remote_racked_tube('A1', build_remote_tube(aliquots: [build_remote_aliquot(sample:
                build_remote_sample(sample_metadata: nil))])),
              build_remote_racked_tube('B1', build_remote_tube(aliquots: [build_remote_aliquot(sample:
                build_remote_sample(sample_metadata: double('sample_metadata',
                                                            sample_common_name: 'species', supplier_name: nil)))])),
              build_remote_racked_tube('C1', build_remote_tube(aliquots: [build_remote_aliquot(sample:
                build_remote_sample(sample_metadata: double('sample_metadata',
                                                            sample_common_name: 'species', supplier_name: 'a supplier name')))])),
              build_remote_racked_tube('D1', build_remote_tube(aliquots: [build_remote_aliquot(sample:
                build_remote_sample(sample_metadata: double('sample_metadata',
                                                            sample_common_name: 'species', supplier_name: 'a supplier name')))]))
            ]
            build_remote_tube_rack(barcode: generate(:barcode), racked_tubes: racked_tubes)
          end

          it_behaves_like 'a partial import of samples'
        end
      end
    end
  end

  describe '#find_or_import_assets_with_barcodes' do
    let(:local_barcode) { generate(:barcode) }
    let(:remote_barcode) { generate(:barcode) }
    let(:non_existant_barcode) { 'NOT_FOUND' }
    let(:remote_labware) do
      SequencescapeClientV2::Labware.new(uuid: SecureRandom.uuid, labware_barcode: { 'human_barcode' => remote_barcode }, type: 'tubes')
    end
    let(:full_remote_labware) { build_remote_tube(barcode: generate(:barcode), uuid: remote_labware.uuid, labware_barcode: remote_labware.labware_barcode) }
    let(:local_asset) { Asset.create!(barcode: local_barcode) }

    before do
      local_asset
      expect(SequencescapeClient).to receive(:labware).with(barcode: [remote_barcode, non_existant_barcode]).and_return([remote_labware])
      # We still need this as we're currently immediately refreshing the resource from SS
      allow(SequencescapeClient).to receive(:find_by_uuid).with(remote_labware.uuid).and_return(full_remote_labware)
    end

    subject(:find_or_import_assets_with_barcodes) do
      Asset.find_or_import_assets_with_barcodes([local_barcode, remote_barcode, non_existant_barcode])
    end

    it 'imports only remote barcodes' do
      expect { find_or_import_assets_with_barcodes }.to change(Asset, :count).by(1)
    end

    it 'does not return an asset that does not exist' do
      expect(find_or_import_assets_with_barcodes.pluck(:barcode)).not_to include(non_existant_barcode)
    end

    it { is_expected.to(satisfy { |array| array.length == 2 }) }
    it { is_expected.to all be_an Asset }

    it 'returns local assets' do
      expect(find_or_import_assets_with_barcodes).to include(local_asset)
    end

    it 'returns a newly registered remote labware' do
      expect(find_or_import_assets_with_barcodes.pluck(:barcode)).to include(remote_barcode)
    end
  end
end
