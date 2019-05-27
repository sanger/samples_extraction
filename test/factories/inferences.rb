FactoryBot.define do
  factory :inference, class: Activities::BackgroundTasks::Inference do
    step_type { create :step_type }
    asset_group { create :asset_group }
  end
end
