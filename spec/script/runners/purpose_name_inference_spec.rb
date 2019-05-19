require 'rails_helper'

RSpec.describe 'PurposeNameInference' do
  RUNNER = "script/runners/purpose_name_inference.rb"

  def run_group(asset_group)
    json = `rails runner -e test #{RUNNER} http://#{asset_group.id}.json`
    FactChanges.new(json).apply(step)
  end

  # TODO:
  # When running an external script, data created during a test is not visible to this new script
  # because everything was created inside a transaction, so the data is rolled back in every
  # test. I did not want to disable this behaviour for the rest of the tests just to run a test for
  # this runner. The runners should be moved to a different project, so for the moment this test
  # will create and destroy all data before the testing transaction is created , and so the runner
  # will be able to find the data in the database; but in future we should solve this by config:
  #
  # Rails.config.use_transactional_fixtures = false
  #
  before(:all) do
    @asset = Asset.create
    @asset2 = Asset.create
    @fact1 = Fact.new(predicate: 'aliquotType', object: '')
    @fact2 = Fact.new(predicate: 'contains', object_asset: @asset2)
    @asset2.facts << (@fact1)
    @asset.facts << (@fact2)
    @asset_group = AssetGroup.create
    @asset_group.update_attributes(assets: [@asset])
  end

  after(:all) do
    [@asset, @asset2, @fact1, @fact2, @asset_group].each(&:destroy)
  end

  def build_instances_for_aliquot(aliquot)
    `rails runner -e test "Fact.find(#{@fact1.id}).update_attributes(object: '#{aliquot}')"`
    @asset_group
  end


  let(:activity) { create(:activity, state: 'running') }
  let(:runner_name) { 'purpose_name_inference.rb' }
  let(:step) { build :step }


  it 'infers the purpose DNA Stock for DNA aliquots' do
    asset_group = build_instances_for_aliquot('DNA')
    run_group(asset_group)
    asset = asset_group.assets.first
    expect(asset.facts.with_predicate('purpose').first.object).to eq('DNA Stock Plate')
  end

  it 'infers the purpose RNA Stock for RNA aliquots' do
    asset_group = build_instances_for_aliquot('RNA')
    run_group(asset_group)
    asset = asset_group.assets.first
    expect(asset.facts.with_predicate('purpose').first.object).to eq('RNA Stock Plate')
  end

  it 'infers the purpose Stock for any other aliquot' do
    asset_group = build_instances_for_aliquot('anything')
    run_group(asset_group)
    asset = asset_group.assets.first
    expect(asset.facts.with_predicate('purpose').first.object).to eq('Stock Plate')
  end

end
