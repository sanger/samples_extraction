FactoryGirl.define do
  factory :activity do
    activity_type { create :activity_type }
    asset_group { create :asset_group }
  end
end
