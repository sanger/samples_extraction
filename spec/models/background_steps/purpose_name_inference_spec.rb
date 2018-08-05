require 'rails_helper'

RSpec.describe BackgroundSteps::PurposeNameInference do

  def build_instance
    build_instance_for_aliquot('DNA')
  end

  let(:activity) { create(:activity) }

  def build_instance_for_aliquot(aliquot)
    asset = create(:asset)
    asset2 = create(:asset)
    asset2.add_facts(create(:fact, predicate: 'aliquotType', object: aliquot))
    asset.add_facts(create(:fact, predicate: 'contains', object_asset: asset2))

    asset_group = create(:asset_group)
    asset_group.update_attributes(assets: [asset])

    BackgroundSteps::PurposeNameInference.new(step_type: create(:step_type), 
      activity: activity,
      asset_group: asset_group)    
  end

  it_behaves_like 'background step'

  it 'infers the purpose DNA Stock for DNA aliquots' do
    step = build_instance_for_aliquot('DNA')
    step.execute_actions
    asset = step.asset_group.assets.first
    expect(asset.facts.with_predicate('purpose').first.object).to eq('DNA Stock Plate')
  end

  it 'infers the purpose RNA Stock for RNA aliquots' do
    step = build_instance_for_aliquot('RNA')
    step.execute_actions
    asset = step.asset_group.assets.first
    expect(asset.facts.with_predicate('purpose').first.object).to eq('RNA Stock Plate')
  end

  it 'infers the purpose Stock for any other aliquot' do
    step = build_instance_for_aliquot('anything')
    step.execute_actions
    asset = step.asset_group.assets.first
    expect(asset.facts.with_predicate('purpose').first.object).to eq('Stock Plate')
  end

end