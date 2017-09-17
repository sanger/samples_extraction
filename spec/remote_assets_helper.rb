module RemoteAssetsHelper
	def build_remote_plate
		purpose = double('purpose', name: 'A purpose')

		double('remote_asset', {
			uuid: SecureRandom.uuid,
			wells: [build_well('A1'), build_well('A4')],
			plate_purpose: purpose
			})		
	end

	def build_well(location)
		double('well', {aliquots: [build_remote_aliquot], location: location, uuid: SecureRandom.uuid})
	end

	def build_remote_tube
		purpose = double('purpose', name: 'A purpose')

		double('remote_asset', {
			uuid: SecureRandom.uuid,
			plate_purpose: purpose,
			aliquots: [build_remote_aliquot]
			})		
	end

	def build_remote_aliquot
		double('aliquot', sample: build_sample)
	end

	def build_sample
		double('sample', 
			sanger: double('sanger', { sample_id: 'TEST-123', name: 'a sample name'}), 
			supplier: double('supplier', {sample_name: 'a supplier'}))
	end

end