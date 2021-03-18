FactoryBot.define do
  factory :asset do
    after(:build) do |asset|
      if (Rails.configuration.respond_to?(:testing_barcodes) && asset.barcode.nil?)
        asset.update_attributes(:barcode => Rails.configuration.testing_barcodes.pop)
      end
    end

    factory :plate do
      transient do
        well_attributes do
          []
        end
      end

      barcode

      facts do
        well_attributes.map do |attributes|
          well = build :well_with_samples, attributes
          build :fact, predicate: 'contains', object_asset: well
        end
      end
    end

    factory :well_with_samples do
      transient do
        supplier_sample_name { 'Sample Name' }
        sample_uuid { SecureRandom.uuid }
      end

      barcode { nil }

      facts do
        [
          build(:fact, predicate: 'supplier_sample_name', object: supplier_sample_name),
          build(:fact, predicate: 'sample_uuid', object: sample_uuid)
        ]
      end
    end
  end
end
