FactoryBot.define do
  factory :asset do
    factory :plate do
      transient { well_attributes { [] } }

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
