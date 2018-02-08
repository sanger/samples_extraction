require 'rails_helper'
require 'remote_assets_helper'

RSpec.describe AssetGroupsController, type: :controller do
  include RemoteAssetsHelper

  before do
    @asset_group = FactoryGirl.create :asset_group
    @activity_type = FactoryGirl.create :activity_type
    @activity = FactoryGirl.create :activity, {
      :activity_type => @activity_type, 
      :asset_group => @asset_group}
  end

  context "adding a new barcode to the asset group" do
    context "when the barcode is in the database" do
      setup do
        @barcode = FactoryGirl.generate :barcode
        @asset = FactoryGirl.create(:asset, {:barcode => @barcode})
      end

      it "add the new asset to the group" do
        expect{
          post :update, params: {:asset_group => {:add_barcode => @barcode}, 
            :id => @asset_group.id, :activity_id => @activity.id}
        }.to change{@asset_group.assets.count}.by(1)
      end
    end

    context "when the barcode is not the database" do
      setup do
        @barcode = FactoryGirl.generate :barcode
      end
      context "when it is in Sequencescape" do
        let(:SequencescapeClient) { double('sequencescape_client')}
        setup do
          remote_asset = build_remote_tube(barcode: @barcode.to_s)
          stub_client_with_asset(SequencescapeClient, remote_asset)
        end
        it "retrieve the asset from Sequencescape" do
          expect{
            post :update, params: {:asset_group => {:add_barcode => @barcode}, 
                :id => @asset_group.id, :activity_id => @activity.id}
          }.to change{@asset_group.assets.count}.by(1)
        end
      end

      context "when it is a creatable barcode" do
        setup do
          @creatable_barcode = FactoryGirl.generate :barcode_creatable
        end
        it "create a new asset" do
          expect{
            post :update, params: {:asset_group => {
              :add_barcode => @creatable_barcode
              }, 
              :id => @asset_group.id, :activity_id => @activity.id}
          }.to change{@asset_group.assets.count}.by(1)
        end
      end
    end
  end
end
