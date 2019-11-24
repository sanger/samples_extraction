FactoryBot.define do
  factory :asset do
    trait :with_barcode do
      barcode { generate :barcode }
    end
    factory :tube, class: Asset do
      facts { [ create(:tube_fact)  ] }

      trait :inside_rack do
        transient do
          parent { nil }
          location { nil }
        end
        after(:create) do |tube, evaluator|
          if evaluator.parent
            evaluator.parent.facts << create(:fact, predicate: 'contains', object_asset_id: tube.id, literal: false)
            tube.facts << create(:fact, predicate: 'parent', object_asset: evaluator.parent, literal: false)
          end
          if evaluator.location
            tube.facts << create(:fact, predicate: 'location', object: evaluator.location, literal: true)
          end
        end
      end
    end

    factory :plate, class: Asset do
      facts { [ create(:plate_fact) ] }
    end

    factory :tube_rack, class: Asset do
      facts { [ create(:tube_rack_fact) ] }
    end
  end

end
