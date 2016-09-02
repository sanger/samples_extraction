FactoryGirl.define do
  factory :instrument do
    barcode  { FactoryGirl.generate :barcode }
  end
end
