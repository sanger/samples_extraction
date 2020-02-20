require 'rails_helper'
require 'remote_assets_helper'
require 'support/activity_support'

RSpec.feature 'Sequencescape Updates', type: :feature, js: true, browser: true do
  include RemoteAssetsHelper
  include ActivitySupport

  setup do
    Rails.configuration.run_step_actions_from_class = true
  end

  let!(:activity_type) { create(:activity_type, name: 'Test') }
  let!(:instrument) { create(:instrument, barcode: '1', activity_types: [activity_type]) }
  let!(:kit_type) { create :kit_type, activity_type: activity_type }
  let!(:user) { create(:user, barcode: '1', role: 'administrator', username: 'TEST') }
  let!(:kit) { create :kit, kit_type: kit_type}
  let!(:plate_name) { "a plate name" }
  let!(:wells) {
    [
      build_remote_well('C1', aliquots: [build_remote_aliquot(sample:
        build_remote_sample(sample_metadata: double('sample_metadata',
          sample_common_name: 'species', supplier_name: 'a supplier name')))]),
      build_remote_well('D1', aliquots: [build_remote_aliquot(sample:
        build_remote_sample(sample_metadata: double('sample_metadata',
          sample_common_name: 'species', supplier_name: 'a supplier name')))])
    ]
  }
  let!(:plate1) {
    p=create(:plate, remote_digest: '1234')
    p.generate_barcode
    p.facts << create(:fact, predicate: 'plateName', object: plate_name, literal: true)
    remote = build_remote_plate(barcode: p.barcode, wells: wells)
    stub_client_with_asset(SequencescapeClient, remote)
    p.update_attributes(uuid: remote.uuid)
    p
  }
  let!(:step_type) {
    st = create(:step_type, n3_definition: %Q{
      { ?plate :a :Plate .
        ?plate :is :NotStarted .
        } => {
          :step :stepTypeName """Stamp in a new plate""" .
          :step :stepAction """transfer_plate_to_plate.rb""" .
          :step :createAsset { ?plate2 :a :Plate .}.
          :step :addFacts { ?plate :transfer ?plate2 .}.
          :step :addFacts { ?plate2 :is :Started .}.
          :step :addFacts { ?plate2 :transferredFrom ?plate .}.
          :step :addFacts { ?plate2 :barcodeType :NoBarcode .}.
          :step :addFacts { ?plate :is :Started .}.
          :step :removeFacts { ?plate :is :NotStarted .}.
          :step :unselectAsset ?plate .
      }.
    })
    activity_type.step_types << st
    st
  }

  let!(:step_type2) {
    st = create(:step_type, n3_definition: %Q{
      { ?plate :a :Plate .
        ?plate :is :Started .
        } => {
          :step :stepTypeName """Update new plate in Sequencescape""" .
          :step :addFacts { ?plate :pushTo :Sequencescape .}.
      }.
    })
    activity_type.step_types << st
    st
  }

  context 'with a logged user' do
    before do
      user_login(user)
    end
    context "with a created activity" do
      before do
        start_activity(kit)
      end

      context "when we create a new plate" do
        before do
          scan_asset(plate1)
          expect(page).to have_content(plate1.barcode, wait: 10)

          allow(SequencescapeClient).to receive(:version_1_find_by_uuid).and_return(nil)
          allow(SequencescapeClient).to receive(:create_plate).and_return(instance)
          allow(SequencescapeClient).to receive(:update_extraction_attributes).and_return(true)

          click_on("Stamp in a new plate", match: :first)

          expect(page).to have_content("Update new plate in Sequencescape", wait: 10)
        end

        context "when we update it in Sequencescape" do
          let(:barcode) { generate :plate_barcode }
          let(:instance) { asset_version_1(build_remote_plate(barcode: barcode)) }

          scenario "it updates the plate in Sequencescape" do
            expect(SequencescapeClient).to receive(:create_plate)
            expect(SequencescapeClient).to receive(:update_extraction_attributes)

            click_on("Update new plate in Sequencescape", match: :first)
            expect(page).to have_content(barcode)
          end
        end
      end
    end
  end
end
