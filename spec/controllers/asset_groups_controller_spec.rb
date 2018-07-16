require 'rails_helper'
require 'remote_assets_helper'

RSpec.describe AssetGroupsController, type: :controller do
  include RemoteAssetsHelper

  let(:asset_group) { create :asset_group }
  let(:activity_type) { create :activity_type }
  let(:activity) { create :activity, {activity_type: activity_type, asset_group: asset_group } }

  context "adding a new asset to the asset group" do
    
    let(:barcode) { generate :barcode }
    let(:asset) { create :asset, barcode: barcode }

    context "when the asset is in the database" do
      context 'finding by uuid' do
        it "add the new asset to the group" do
          expect{
            post :update, params: {:asset_group => {:assets => [asset.uuid]}, 
              :id => asset_group.id, :activity_id => activity.id}
          }.to change{asset_group.assets.count}.by(1)
        end
      end
      context 'finding by barcode' do
        it "add the new asset to the group" do
          expect{
            post :update, params: {:asset_group => {:assets => [asset.barcode]}, 
              :id => asset_group.id, :activity_id => activity.id}
          }.to change{asset_group.assets.count}.by(1)
        end        
      end
    end

    context "when the asset is not in the database" do
      let(:barcode) { '1234' }
      let(:uuid) { SecureRandom.uuid }
      let(:SequencescapeClient) { double('sequencescape_client')}
      let(:remote_asset) { build_remote_tube(barcode: barcode, uuid: uuid) } 

      before do
        stub_client_with_asset(SequencescapeClient, remote_asset)
      end

      context "when it is in Sequencescape" do

        context 'finding by uuid' do
          it "retrieves the asset from Sequencescape" do
            expect{
              post :update, params: {:asset_group => {:assets => [uuid]}, 
                  :id => asset_group.id, :activity_id => activity.id}
            }.to change{asset_group.assets.count}.by(1)
          end
        end

        context 'finding by barcode' do
          it "retrieves the asset from Sequencescape" do
            expect{
              post :update, params: {:asset_group => {:assets => [barcode]}, 
                  :id => asset_group.id, :activity_id => activity.id}
            }.to change{asset_group.assets.count}.by(1)
          end
        end
      end

      context "when it is not in Sequencescape" do

        it 'does not retrieve anything' do
          post :update, params: {:asset_group => {:assets => [SecureRandom.uuid]}, 
              :id => asset_group.id, :activity_id => activity.id}
          expect(asset_group.assets.count).to eq(0)
        end
      end

      context "when it is a creatable barcode" do
        let(:creatable_barcode) { generate :barcode_creatable }

        it "creates a new asset" do
          expect{
            post :update, params: {:asset_group => {
              :assets => [creatable_barcode]
              }, 
              :id => asset_group.id, :activity_id => activity.id}
          }.to change{asset_group.assets.count}.by(1)
        end
      end
    end
  end
end
