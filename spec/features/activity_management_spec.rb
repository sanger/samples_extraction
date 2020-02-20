require 'rails_helper'
require 'remote_assets_helper'
require 'support/activity_support'

RSpec.feature 'Activity Management', type: :feature, js: true, browser: true do
  include RemoteAssetsHelper
  include ActivitySupport

  let!(:activity_type) { create(:activity_type, name: 'Test') }
  let!(:instrument) { create(:instrument, barcode: '1', activity_types: [activity_type]) }
  let!(:kit_type) { create :kit_type, activity_type: activity_type }
  let!(:user) { create(:user, barcode: '1', role: 'administrator', username: 'TEST') }
  let!(:kit) { create :kit, kit_type: kit_type}
  let!(:plate_name) { "a plate name" }
  let!(:plate1) {
    p=create(:plate, remote_digest: '1234')
    p.generate_barcode
    p.facts << create(:fact, predicate: 'plateName', object: plate_name, literal: true)
    remote = build_remote_plate(barcode: p.barcode)
    stub_client_with_asset(SequencescapeClient, remote)
    p.update_attributes(uuid: remote.uuid)
    p
  }
  let!(:step_type) {
    st = create(:step_type, n3_definition: %Q{
      { ?plate :a :Plate .
        ?plate :is :NotStarted .
        } => {
          :step :stepTypeName """Transfer to new plate""" .
          :step :unselectAsset ?plate .
          :step :removeFacts { ?plate :is :NotStarted .}.
          :step :addFacts { ?plate :is :Started .}.
          :step :createAsset { ?plate2 :a :Plate .} .
          :step :addFacts { ?plate2 :status :plateReadyForSecondTransfer .}.
          :step :addFacts { ?plate2 :transferredFrom ?plate .}.
          :step :addFacts { ?plate :transfer ?plate2 . }.
      }.
    })
    activity_type.step_types << st
    st
  }
  let!(:step_type2) {
    st = create(:step_type, n3_definition: %Q{
      {
        ?plate :a :Plate .
        ?plate :status :plateReadyForSecondTransfer .
        } => {
          :step :stepTypeName """Transfer to 2 new plates""" .
          :step :unselectAsset ?plate .
          :step :createAsset { ?plate2 :a :Plate .} .
          :step :createAsset { ?plate3 :a :Plate .} .
          :step :addFacts { ?plate2 :status :plateReadyForThirdTransfer .}.
          :step :addFacts { ?plate3 :status :plateReadyForThirdTransfer .}.
          :step :addFacts { ?plate2 :transferredFrom ?plate .}.
          :step :addFacts { ?plate :transfer ?plate2 . }.
          :step :addFacts { ?plate3 :transferredFrom ?plate .}.
          :step :addFacts { ?plate :transfer ?plate3 . }.

      }.
    })
    activity_type.step_types << st
    st
  }


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

        expect(page).not_to have_content(plate1.barcode, wait: 100)
      end

      context 'if we scan an asset that does not exist' do
        let(:error_barcode) { 'error'}
        before do
          allow(SequencescapeClient).to receive(:get_remote_asset).with([error_barcode], []).and_return([nil],['error'])
        end
        scenario "we have an error message" do
          scan_barcode(error_barcode)

          expect(page).to have_content("Cannot find the barcode", wait: 10)
        end
      end

      scenario "we can run a workflow on it" do
        scan_asset(plate1)

        expect(page).to have_content("Transfer to new plate", wait: 10)

        expect(find("div.active")).to have_content(plate_name, wait: 10)
        expect(page).not_to have_content("Transfer to 2 new plates")

        click_on("Transfer to new plate", match: :first)

        expect(page).to have_content("transferredFrom", wait: 10)
        expect(find("div.active")).not_to have_content(plate_name, wait: 10)
        expect(page).not_to have_content("Transfer to new plate")

        click_on("Transfer to 2 new plates", match: :first)

        expect(page).to have_content("transferredFrom", wait: 10)
        expect(find("div.active")).to have_content("plateReadyForThirdTransfer", wait: 10)

        click_on("Finish activity")
        expect(page).to have_content('This activity was finished')
      end

    end
  end
end
