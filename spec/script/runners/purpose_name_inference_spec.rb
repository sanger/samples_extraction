require 'rails_helper'

require_relative "../../../script/runners/purpose_name_inference.rb"

RSpec.describe 'PurposeNameInference' do


  let(:activity) { create(:activity, state: 'running') }
  let(:runner_name) { 'purpose_name_inference.rb' }
  let(:step) { build :step }

  def run_group(asset_group)
    PurposeNameInference.new(asset_group: asset_group).process.apply(step)
  end

  def build_instances_for_aliquot(aliquot)
    asset = Asset.create
    asset2 = Asset.create
    asset2.facts << (Fact.new(predicate: 'aliquotType', object: aliquot))
    asset.facts << (Fact.new(predicate: 'contains', object_asset: asset2))

    asset_group = AssetGroup.create
    asset_group.update_attributes(assets: [asset])
    asset_group
  end

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
