FactoryBot.define do
  factory :step do
  end

  factory :background_step, :class => 'Activities::BackgroundTasks::BackgroundStep' do
    step_type { create :step_type }
  end


end
