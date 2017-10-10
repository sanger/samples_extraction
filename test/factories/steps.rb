FactoryGirl.define do
  factory :step do
  end

  factory :background_step, :class => 'BackgroundSteps::BackgroundStep' do
    step_type { create :step_type }
  end
end
