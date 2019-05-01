require 'rails_helper'

RSpec.describe FactChanges do
  let(:uuid1) { SecureRandom.uuid }
  let(:uuid2) { SecureRandom.uuid }
  let(:asset_group1) { AssetGroup.new }
  let(:asset1) { Asset.new }
  let(:asset2) { Asset.new }
  let(:relation) { 'rel' }
  let(:property) { 'prop' }
  let(:value) { 'val' }
  let(:updates1) { FactChanges.new }
  let(:updates2) { FactChanges.new }
  let(:fact1) { create :fact, asset: asset1, predicate: property, object: value }
  let(:fact2) { create :fact, asset: asset1, predicate: relation, object_asset: asset2 }
  let(:step) { create :step }
  let(:json) { {:"add_facts" => [["?p", "a", "Plate"]]}.to_json }

  describe '#new' do
    it 'parses a json and loads the config from it' do
      updates = FactChanges.new(json)
      expect(updates.facts_to_add.length).to eq(1)
    end
  end

  describe '#parse_json' do
    let(:updates) { FactChanges.new }
    it 'raises exception when the parsed object is not right' do
      expect{updates.parse_json("something went wrong!")}.to raise_error(StandardError)
    end
    it 'parses a json and loads the changes from it' do
      expect(updates.facts_to_add.length).to eq(0)
      updates.parse_json(json)
      expect(updates.facts_to_add.length).to eq(1)
    end
    it 'parses an empty json' do
      updates.parse_json("{}")
      expect(updates.facts_to_add.length).to eq(0)
    end
    it 'allows to add more changes after parsing' do
      updates.parse_json(json)
      expect(updates.facts_to_add.length).to eq(1)
      updates.add("?q", "a", "Tube")
      expect(updates.facts_to_add.length).to eq(2)
    end
    it 'does not destroy previously loaded changes' do
      updates.add("?q", "a", "Tube")
      expect(updates.facts_to_add.length).to eq(1)
      updates.parse_json(json)
      expect(updates.facts_to_add.length).to eq(2)
    end
  end

  describe '#reset' do
    it 'resets the changes' do
      updates1.add(asset1, property, value)
      updates1.reset
      updates2.merge(updates1)
      expect(updates1.facts_to_add.length).to eq(0)
      expect(updates2.facts_to_add.length).to eq(0)
    end
  end
  describe '#add' do
    it 'adds a new property' do
      expect(updates1.facts_to_add.length).to eq(0)
      updates1.add(asset1, property, value)
      expect(updates1.facts_to_add.length).to eq(1)
    end
    it 'adds a new relation' do
      expect(updates1.facts_to_add.length).to eq(0)
      updates1.add(asset1, relation, asset2)
      expect(updates1.facts_to_add.length).to eq(1)
    end
  end
  describe '#add_remote' do
    it 'adds a new fact in the facts to add list' do
      expect(updates1.facts_to_add.length).to eq(0)
      updates1.add_remote(asset1, relation, asset2)
      expect(updates1.facts_to_add.length).to eq(1)
    end
  end
  describe '#remove' do
    it 'adds a fact to remove' do
      expect(updates1.facts_to_destroy.length).to eq(0)
      updates1.remove(fact1)
      expect(updates1.facts_to_destroy.length).to eq(1)
    end
  end

  describe '#remove_where' do
    it 'adds a property to remove' do
      expect(updates1.facts_to_destroy.length).to eq(0)
      updates1.remove_where(fact1.asset, fact1.predicate, fact1.object)
      expect(updates1.facts_to_destroy.length).to eq(1)
    end
    it 'adds a relation to remove' do
      expect(updates1.facts_to_destroy.length).to eq(0)
      updates1.remove_where(fact2.asset, fact2.predicate, fact2.object_asset)
      expect(updates1.facts_to_destroy.length).to eq(1)
    end
    it 'is able to work with uuids' do
      expect(updates1.facts_to_destroy.length).to eq(0)
      updates1.remove_where(fact2.asset.uuid, fact2.predicate, fact2.object_asset.uuid)
      expect(updates1.facts_to_destroy.length).to eq(1)
    end
    it 'does not add the same removal twice' do
      expect(updates1.facts_to_destroy.length).to eq(0)
      updates1.remove_where(fact1.asset, fact1.predicate, fact1.object)
      updates1.remove_where(fact1.asset, fact1.predicate, fact1.object)
      expect(updates1.facts_to_destroy.length).to eq(1)
    end
  end

  describe '#create_assets' do
    it 'adds the list to the assets to create' do
      updates1.create_assets(["?p", "?q", "?r"])
      expect(updates1.assets_to_create.length).to eq(3)
    end
    it 'does not add twice the same asset' do
      updates1.create_assets(["?p", "?q", "?p"])
      expect(updates1.assets_to_create.length).to eq(2)
    end
    it 'does not raise error when referring to an asset not referred before' do
      expect{updates1.create_assets([SecureRandom.uuid])}.not_to raise_error
    end

  end

  describe '#delete_assets' do
    let(:asset1) { Asset.create(uuid: SecureRandom.uuid)}
    let(:asset2) { Asset.create(uuid: SecureRandom.uuid)}
    let(:asset3) { Asset.create(uuid: SecureRandom.uuid)}
    it 'adds the list to the assets to destroy' do
      updates1.delete_assets([asset1.uuid, asset2.uuid, asset3.uuid])
      expect(updates1.assets_to_destroy.length).to eq(3)
    end
    it 'does not add twice the same asset' do
      updates1.delete_assets([asset1.uuid, asset2.uuid, asset1.uuid])
      expect(updates1.assets_to_destroy.length).to eq(2)
    end
    it 'raises error when referring to an asset not referred before ' do
      expect{updates1.delete_assets([SecureRandom.uuid])}.to raise_error(StandardError)
    end
  end

  describe '#add_assets' do
    let(:asset1) { Asset.create(uuid: SecureRandom.uuid)}
    let(:asset2) { Asset.create(uuid: SecureRandom.uuid)}
    let(:asset_group) { AssetGroup.create(uuid: SecureRandom.uuid)}
    it 'adds the changes to the list of assets to add one for each asset' do
      updates1.add_assets(asset_group, [asset1.uuid, asset2.uuid])
      expect(updates1.assets_to_add.length).to eq(2)
    end
    it 'does not add twice the same asset' do
      updates1.add_assets(asset_group, [asset1.uuid, asset1.uuid])
      expect(updates1.assets_to_add.length).to eq(1)
    end
    it 'raises error when referring to an asset group not referred before ' do
      expect{updates1.add_assets(SecureRandom.uuid, [asset1.uuid, asset2.uuid])}.to raise_error(StandardError)
    end

  end

  describe '#remove_assets' do
    let(:asset1) { Asset.create(uuid: SecureRandom.uuid)}
    let(:asset2) { Asset.create(uuid: SecureRandom.uuid)}
    let(:asset_group) { AssetGroup.create(uuid: SecureRandom.uuid)}
    it 'adds the changes to the list of assets to add one for each asset' do
      updates1.remove_assets(asset_group, [asset1.uuid, asset2.uuid])
      expect(updates1.assets_to_remove.length).to eq(2)
    end
    it 'does not add twice the same asset' do
      updates1.remove_assets(asset_group, [asset1.uuid, asset1.uuid])
      expect(updates1.assets_to_remove.length).to eq(1)
    end
    it 'raises error when referring to an asset group not referred before ' do
      expect{updates1.remove_assets(SecureRandom.uuid, [asset1.uuid, asset2.uuid])}.to raise_error(StandardError)
    end

  end


  describe '#merge' do

    it 'returns another FactChanges object' do
      expect(updates1.merge(updates2).kind_of?(FactChanges)).to eq(true)
    end
    it 'merges changes from other objects' do
      expect(updates1.facts_to_add.length).to eq(0)
      expect(updates2.facts_to_add.length).to eq(0)
      updates1.add(asset1, relation, asset2)
      updates2.add(asset2, relation, asset1)
      expect(updates1.facts_to_add.length).to eq(1)
      expect(updates2.facts_to_add.length).to eq(1)
      updates2.merge(updates1)
      expect(updates1.facts_to_add.length).to eq(1)
      expect(updates2.facts_to_add.length).to eq(2)
    end
    it 'does not merge changes more than once' do
      expect(updates1.facts_to_add.length).to eq(0)
      expect(updates2.facts_to_add.length).to eq(0)
      updates1.add(asset1, relation, asset2)
      expect(updates1.facts_to_add.length).to eq(1)
      expect(updates2.facts_to_add.length).to eq(0)
      updates2.merge(updates1)
      updates2.merge(updates1)
      updates2.merge(updates1)
      expect(updates1.facts_to_add.length).to eq(1)
      expect(updates2.facts_to_add.length).to eq(1)
    end
    it 'does not merge duplicates' do
      expect(updates1.facts_to_add.length).to eq(0)
      expect(updates2.facts_to_add.length).to eq(0)
      updates1.add(asset1, relation, asset2)
      updates2.add(asset1, relation, asset2)
      expect(updates1.facts_to_add.length).to eq(1)
      expect(updates2.facts_to_add.length).to eq(1)
      updates2.merge(updates1)
      expect(updates1.facts_to_add.length).to eq(1)
      expect(updates2.facts_to_add.length).to eq(1)
    end
  end

  describe '#apply' do
    it 'applies the changes in the database' do
      expect(Operation.all.count).to eq(0)
      expect(updates1.facts_to_add.length).to eq(0)
      expect(asset1.facts.count).to eq(0)
      updates1.add(asset1, relation, asset2)
      updates1.apply(step)
      expect(asset1.facts.count).to eq(1)
      expect(Operation.all.count).to eq(1)
    end
  end
end
