require 'rails_helper'

RSpec.feature 'Activity Management', type: :feature, js: true do
  let!(:activity_type) { create(:activity_type, name: 'Test') }
  let!(:instrument) { create(:instrument, barcode: '1', activity_types: [activity_type]) }
  let!(:kit_type) { create :kit_type, activity_type: activity_type }
  let!(:user) { create(:user, barcode: '1', role: 'administrator', username: 'TEST') }
  let!(:kit) { create :kit, kit_type: kit_type}

  before do
    Capybara.current_driver = :selenium_chrome_headless
  end

  context 'with a logged user' do
    before do
      visit '/'
      find('.logged-out').click
      fill_in('Scan a user barcode', with: user.barcode)
      click_on('Login')
    end
    scenario "User can create an activity" do
      click_on('Use')
      fill_in('Scan a kit barcode', with: kit.barcode)
      click_on('Create activity')

      expect(page).to have_content('Activity was successfully created')
    end

  end
end
