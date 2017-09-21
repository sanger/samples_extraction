module RemoteAssetsHelper
	def build_remote_plate
		purpose = double('purpose', name: 'A purpose')
		obj = {
			uuid: SecureRandom.uuid,
			wells: [build_well('A1'), build_well('A4')],
			plate_purpose: purpose
		}
		my_double = double('remote_asset', obj)		
		allow(my_double).to receive(:attribute_groups).and_return(obj)

		allow(my_double).to receive(:class).and_return(Sequencescape::Plate)

		my_double
	end

	def build_well(location)
		double('well', {aliquots: [build_remote_aliquot], location: location, uuid: SecureRandom.uuid})
	end

	def build_remote_tube
		purpose = double('purpose', name: 'A purpose')

		my_double = double('remote_asset', {
			uuid: SecureRandom.uuid,
			plate_purpose: purpose,
			aliquots: [build_remote_aliquot]
			})		

		allow(my_double).to receive(:class).and_return(Sequencescape::Plate)
		my_double
	end

	def build_remote_aliquot
		double('aliquot', sample: build_sample)
	end

	def build_sample
		double('sample', 
			sanger: double('sanger', { sample_id: 'TEST-123', name: 'a sample name'}), 
			supplier: double('supplier', {sample_name: 'a supplier'}),
			updated_at: Time.now.to_s
			)
	end

	def stub_client_with_asset(double, asset)
		type = (asset.class==Sequencescape::Plate) ? :plate : :tube
	  allow(double).to receive(:find_by_uuid).with(asset.uuid, type).and_return(asset)
		allow(double).to receive(:get_remote_asset).with(asset.barcode).and_return(asset)
		allow(double).to receive(:get_remote_asset).with(asset.uuid).and_return(asset)
	end

end