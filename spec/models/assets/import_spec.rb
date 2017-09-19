require 'rails_helper'
require 'remote_assets_helper'

RSpec.describe 'Asset::Import' do
	include RemoteAssetsHelper

  context '#find_or_import_asset_with_barcode' do
  	context 'when importing an asset that does not exist' do
  		setup do
  			allow(SequencescapeClient).to receive(:get_remote_asset).and_return(nil)
  		end
  		it 'should raise a NotFound exception at the end' do
  			expect{Asset.find_or_import_asset_with_barcode('NOT_FOUND')}.to raise_exception Asset::Import::NotFound
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
			setup do
				@barcode_plate = "1"
        @remote_plate_asset = build_remote_plate
				allow(@remote_plate_asset).to receive(:class).and_return(Sequencescape::Plate)
				SequencescapeClient = double('sequencescape_client')
        allow(SequencescapeClient).to receive(:find_by_uuid).with(@remote_plate_asset.uuid).and_return(@remote_plate_asset)
				allow(SequencescapeClient).to receive(:get_remote_asset).with(@barcode_plate).and_return(@remote_plate_asset)
				allow(SequencescapeClient).to receive(:get_remote_asset).with(@remote_plate_asset.uuid).and_return(@remote_plate_asset)
			end

			it 'should create the corresponding facts from the json' do
				@asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
				@asset.facts.reload
				expect(@asset.facts.count).to eq(7)
			end

		  context 'for the first time' do
		  	it 'should create the local asset' do
		  		expect(Asset.count).to eq(0)
		  		Asset.find_or_import_asset_with_barcode(@barcode_plate)
		  		expect(Asset.count>0).to eq(true)
		  	end
		  end
		  context 'already imported' do
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
		  			expect{remote_facts.each(&:reload)}.not_to raise_exception ActiveRecord::RecordNotFound
		  		end
		  	end

		  	context 'when the local copy is out of date' do
		  		setup do
		  			@asset.update_attributes(remote_digest: 'RANDOM')
		  		end
		  		it 'should destroy any remote facts' do
		  			remote_facts = @asset.facts.from_remote_asset
		  			remote_facts.each(&:reload)
		  			Asset.find_or_import_asset_with_barcode(@barcode_plate)	
		  			expect{remote_facts.each(&:reload)}.to raise_exception ActiveRecord::RecordNotFound
		  		end
		  		it 'should re-create new remote facts' do
		  			count = @asset.facts.from_remote_asset.count
		  			@asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
		  			@asset.facts.reload
		  			expect(@asset.facts.from_remote_asset.count).to eq(count)
		  		end
		  	end

		  end
  	end
  end
end