FactoryGirl.define do
  factory :step do
  end

  factory :background_step, :class => 'BackgroundSteps::BackgroundStep' do
    step_type { create :step_type }
  end

  factory :inference, :class => 'BackgroundSteps::Inference' do
    step_type { create :step_type }
    asset_group { create :asset_group }
  end

end
