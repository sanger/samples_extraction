require 'rails_helper'
require 'remote_assets_helper'
RSpec.feature 'Activity Management', type: :feature, js: true do
  let!(:activity_type) { create(:activity_type, name: 'Test') }
  let!(:instrument) { create(:instrument, barcode: '1', activity_types: [activity_type]) }
  let!(:kit_type) { create :kit_type, activity_type: activity_type }
  let!(:user) { create(:user, barcode: '1', role: 'administrator', username: 'TEST') }
  let!(:kit) { create :kit, kit_type: kit_type}
  let!(:plate1) {
    p=create(:plate)
    p.generate_barcode
    remote = build_remote_plate(barcode: p.barcode)
    stub_client_with_asset(SequencescapeClient, remote)
    p.update_attributes(uuid: remote.uuid)
    p
  }
  include RemoteAssetsHelper
  before do
    @mocked_redis = MockRedis.new
    ActionController::Base.allow_forgery_protection = true
    allow(ActivityChannel).to receive(:redis).and_return(@mocked_redis)
    #allow(ActionCable.server.pubsub).to receive(:redis_connection_for_subscriptions).and_return(@mocked_redis)
    Capybara.current_driver = :selenium_chrome
  end

  def user_login(user)
    visit '/'
    find('.logged-out').click
    fill_in('Scan a user barcode', with: user.barcode)
    click_on('Login')
  end

  def start_activity(kit)
    click_on('Use')
    fill_in('Scan a kit barcode', with: kit.barcode)
    click_on('Create activity')
  end

  def scan_asset(asset)
    fill_in('Scan a barcode', with: asset.barcode+"\n")
  end

  context 'with an unlogged user' do
    scenario "user can log in" do
      user_login(user)

      expect(page).to have_content('Logged as TEST')
    end
  end
  context 'with a logged user' do
    before do
      user_login(user)
    end
    scenario "User can create an activity" do
      start_activity(kit)

      expect(page).to have_content('Activity was successfully created')

      click_on("Finish activity")

      expect(page).to have_content('This activity was finished')
    end

    context "with a created activity" do
      before do
        start_activity(kit)
      end

      scenario "we can scan new assets and remove them" do
        scan_asset(plate1)

        expect(page).to have_content(plate1.barcode, wait: 10)

        click_on("Delete")

        expect(page).not_to have_content(plate1.barcode, wait: 10)
      end
    end
  end
end
