require 'rails_helper'

RSpec.describe 'ChangesSupport::Callbacks' do
  context 'with FactChanges preconfigured' do
    before do
      FactChanges.initialize_barcode_callbacks
    end
    let(:activity) { create :activity }
    let(:step) { create :step, activity: activity, state: Step::STATE_RUNNING }
    context 'when adding a barcode fact' do
      let(:asset) { create :asset}
      let(:barcode) {"1234"}

      it 'sets the barcode into the barcode column of the asset' do
        updates = FactChanges.new
        updates.add(asset, 'barcode', barcode)
        expect{updates.apply(step)}.to change{asset.barcode}.from(nil).to(barcode)
      end
    end
    context 'when removing a barcode fact' do
      let(:asset) { create :asset, barcode: barcode}
      let(:barcode) {"1234"}

      it 'removes the barcode from the column of the asset' do

        updates = FactChanges.new
        updates.remove_where(asset, 'barcode', barcode)
        expect{updates.apply(step)}.to change{asset.barcode}.from(barcode).to(nil)
      end
    end
  end
end
