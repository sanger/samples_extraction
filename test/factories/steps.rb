FactoryBot.define do
  factory :step do
  end

  factory :background_task, :class => 'Steps::BackgroundTasks::BackgroundTask' do
    step_type { create :step_type }
  end


end
