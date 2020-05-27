module RemoteAssetsHelper
	def build_remote_plate(opts = {})
		purpose = double('purpose', name: 'A purpose')
		obj = {
			uuid: SecureRandom.uuid,
			wells: [build_remote_well('A1'), build_remote_well('A4')],
			purpose: purpose,
			type: 'plates'
		}.merge(opts)

		my_double = double('remote_asset', obj)
		allow(my_double).to receive(:attributes).and_return(obj)
		allow(my_double).to receive(:class).and_return(Sequencescape::Plate)

		my_double
	end

	def build_remote_well(location, opts={})
		double('well', {aliquots: [build_remote_aliquot], location: location, position: { "name" => location }, uuid: SecureRandom.uuid}.merge(opts))
	end

	def build_remote_tube_rack(opts = {})
		purpose = double('purpose', name: 'A purpose')
		obj = {
			uuid: SecureRandom.uuid,
			racked_tubes: [build_remote_racked_tube('A1'), build_remote_racked_tube('A4')],
			purpose: purpose,
			type: 'tube_racks'
		}.merge(opts)

		my_double = double('remote_asset', obj)
		allow(my_double).to receive(:attributes).and_return(obj)

		my_double
	end

	def build_remote_racked_tube(coordinate, tube = nil)
		obj = {
			coordinate: coordinate,
			tube: tube || double('tube', tube_standard_options)
		}

		my_double = double('racked_tube', obj)
	end

	def build_remote_tube(opts = {})
		my_double = double('remote_asset', tube_standard_options(opts))

		allow(my_double).to receive(:attributes).and_return(obj)
		allow(my_double).to receive(:class).and_return(Sequencescape::Tube)

		my_double
	end

	def tube_standard_options(opts = {})
		purpose = double('purpose', name: 'A purpose')
		{
			uuid: SecureRandom.uuid,
			type: 'tubes',
			plate_purpose: purpose,
			aliquots: [build_remote_aliquot]
		}.merge(opts)
	end

	def build_remote_aliquot(opts={})
		double('aliquot', {sample: build_remote_sample, study: build_study}.merge(opts))
	end

	def build_study(opts={})
		double('study', {name: 'STDY', uuid: SecureRandom.uuid})
	end

	def build_remote_sample(opts={})
		attrs_for_sample = {
			sanger_sample_id: 'TEST-123',
			name: 'a sample name',
			sample_metadata: double('sample_metadata', {supplier_name: 'a supplier', sample_common_name: 'specie'}),
			#sanger: double('sanger', { sample_id: 'TEST-123', name: 'a sample name'}),
			uuid: SecureRandom.uuid,
			#supplier: double('supplier', {sample_name: 'a supplier'}),
			updated_at: Time.now.to_s
		}.merge(opts)

		sample = double('sample', attrs_for_sample)
		allow(sample).to receive(:attributes).and_return(attrs_for_sample)
		sample
	end

	def stub_client_with_asset(double, asset)
		type = (asset.class==Sequencescape::Plate) ? :plate : :tube
		allow(double).to receive(:find_by_uuid).with(asset.uuid).and_return(asset)
		allow(double).to receive(:get_remote_asset) { nil }
		allow(double).to receive(:get_remote_asset).with(asset.barcode).and_return(asset)
		allow(double).to receive(:get_remote_asset).with(asset.uuid).and_return(asset)
	end
end
