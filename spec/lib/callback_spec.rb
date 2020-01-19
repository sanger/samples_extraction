require 'rails_helper'
RSpec.describe 'Callback' do
  context 'a new callback class' do
    class A < Callback
    end

    it 'can inherit from Callback' do
      expect(A.new.kind_of?(Callback)).to be_truthy
    end
  end
end
