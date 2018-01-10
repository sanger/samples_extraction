require 'rails_helper'

RSpec.describe AssetGroupsController, type: :controller do
  context 'when adding a new asset' do
    let(:asset_group) { create :asset_group }
    context 'when using an uuid' do
      let(:uuid) { SecureRandom.uuid }
      let(:asset_group_params) { {asset_group: [{uuid: uuid}]} }
      
      xit 'adds the barcode using the uuid' do
        expect(asset_group.assets.count).to eq(0)
        put :update, id: asset_group.id, params: asset_group_params
        expect(asset_group..assets.count).to eq(1)
        expect(asset_group.assets.first.uuid).to eq(asset_group_params[:asset_group].first[:uuid])
      end
    end
  end
end