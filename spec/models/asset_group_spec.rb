require 'rails_helper'
require 'remote_assets_helper'
RSpec.describe AssetGroup, type: :model do
  include RemoteAssetsHelper

  context '#update_with_assets' do
    let(:remote_existing_assets) { 3.times.map{build_remote_tube}}
    let(:existing_assets) {
      remote_existing_assets.count.times.map{|i|
        create(:asset, uuid: remote_existing_assets[i].uuid)
      }
    }
    let(:remote_new_assets) {
      2.times.map { build_remote_tube }
    }
    let(:new_assets) {
      remote_new_assets.count.times.map{|i|
        create(:asset, uuid: remote_new_assets[i].uuid)
      }
    }
    let(:group) { create(:asset_group, assets: existing_assets)}
    it 'adds new assets to the group' do
      asset_list = [].concat(existing_assets).concat(new_assets)
      stub_client_with_assets(SequencescapeClient, remote_new_assets)
      expect {
        group.update_with_assets(asset_list)
      }.to change{Operation.count}.and change{group.assets.count}.by(2)
    end
    it 'removes assets not present anymore in the group' do
      stub_client_with_assets(SequencescapeClient, remote_new_assets)
      expect {
        group.update_with_assets(new_assets)
      }.to change{Operation.count}.and change{group.assets.count}.by(-1)
    end

    it 'refreshes the new added assets' do
      asset_list = [].concat(existing_assets).concat(new_assets)
      remotes = [].concat(remote_existing_assets).concat(remote_new_assets)
      stub_client_with_assets(SequencescapeClient, remote_new_assets)
      expect{
        group.update_with_assets(asset_list)
      }.to change{
        new_assets.first.operations.count
      }
    end
  end
end

