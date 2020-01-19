require 'rails_helper'
require 'fact_changes'

RSpec.describe 'FactChangesInitializers' do

  context 'Callbacks' do
    before do
      FactChanges.clear_all_callbacks!
      FactChangesInitializers.setup_changes_callbacks!
    end

    let(:updates) { FactChanges.new }
    let(:inference) { Step.new }
    let(:aliquots) { ['DNA', 'RNA', 'other'] }
    let(:rack) { create :tube_rack }

  end
end
