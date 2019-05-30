FactoryBot.define do
  factory :inference, class: Steps::BackgroundTasks::Inference do
    step_type { create :step_type }
    asset_group { create :asset_group }
  end
end
