FactoryGirl.define do
  factory :user_with_barcode, :class => User  do
    barcode  { FactoryGirl.generate :barcode }
  end

  sequence :barcode do |n|
    n
  end
end
