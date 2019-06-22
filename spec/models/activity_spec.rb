require 'rails_helper'

RSpec.describe Activity, type: :model do
  context '#for_user' do
    it 'returns the activities that the user has perform at least one action' do
      user = create :user
      step = create :step, user: user
      step2 = create :step

      act1 = create :activity, steps: [step]
      act2 = create :activity, steps: [step2]

      expect(Activity.for_user(user)).to eq([act1])
    end
  end
end
