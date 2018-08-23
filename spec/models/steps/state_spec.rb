require 'rails_helper'

RSpec.describe Steps::State do
  let(:step) { create :step }
  context 'when changing state to complete' do
    it 'sets the timestamp for finished_at' do
      step.update_attributes(state: 'complete')
      expect(step.finished_at.nil?).to eq(false)
    end
  end
  context 'when changing state to running' do
    it 'sets the timestamp for started_at' do
      step.update_attributes(state: 'running')
      expect(step.started_at.nil?).to eq(false)
    end
  end  
end