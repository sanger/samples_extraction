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

  describe '#to_json' do
    let(:updates) { FactChanges.new }
    it 'displays the contents of the object in json format' do
      updates.parse_json(json)
      expect(updates.to_json.kind_of?(String)).to eq(true)
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
  describe '#apply' do
    context 'when the object contains errors' do
      it 'stores the messages and throws an exception' do
        updates1.set_errors(["hi"])
        expect{updates1.apply(step)}.to raise_error(StandardError)
      end
    end
    context 'with add' do
      it 'applies a new added property' do
        updates1.add(asset1, property, value)
        expect{
          updates1.apply(step)
        }.to change{asset1.facts.count}.by(1)
        .and change{Operation.count}.by(1)
      end
      it 'applies a new added relation' do
        updates1.add(asset1, relation, asset2)
        expect{
          updates1.apply(step)
        }.to change{asset1.facts.count}.by(1)
        .and change{Operation.count}.by(1)
      end
      it 'is able to add facts to assets created before' do
        updates1.create_assets(['?p'])
        updates1.add('?p', property, value)
        expect{updates1.apply(step)}.to change{Asset.count}.by(1)
        .and change{Fact.count}.by(1)
      end
    end
    context 'with add_remote' do
      it 'adds a new remote fact' do
        updates1.add_remote(asset1, relation, asset2)
        expect{
          updates1.apply(step)
        }.to change{asset1.facts.count}.by(1)
        .and change{Operation.count}.by(1)

        expect(asset1.facts.first.is_remote?).to eq(true)
      end
    end
    context 'with remove' do
      it 'removes an already existing fact' do
        asset1.facts << fact1
        updates1.remove(fact1)
        expect{
          updates1.apply(step)
        }.to change{asset1.facts.count}.by(-1)
        .and change{Operation.count}.by(1)
      end
    end

    context 'with remove_where' do
      let(:fact2) { create(:fact, predicate: 'cond1', object: 'val')}
      let(:fact3) { create(:fact, predicate: 'cond2', object: 'val')}
      let(:fact4) { create(:fact, predicate: 'cond1', object: 'val')}

      it 'removes facts with a condition' do
        asset1.facts << [fact1, fact2, fact3, fact4]
        updates1.remove_where(asset1, 'cond1', 'val')
        expect{
          updates1.apply(step)
        }.to change{asset1.facts.count}.by(-2)
        .and change{Operation.count}.by(2)
      end
    end

    context 'with create_assets' do
      it 'creates the assets provided' do
        updates1.create_assets(["?p", "?q", "?r"])
        expect{updates1.apply(step)}.to change{Asset.count}.by(3)
        .and change{Operation.count}.by(3)
      end
    end

    context 'with delete_assets' do
      let(:asset3) { Asset.create }
      let(:asset4) { Asset.create }
      it 'deletes the assets provided' do
        updates1.delete_assets([asset3, asset4])
        expect{updates1.apply(step)}.to change{Asset.count}.by(-2)
        .and change{Operation.count}.by(2)
      end
    end

    context 'with add_assets' do
      let(:asset1) { Asset.create(uuid: SecureRandom.uuid)}
      let(:asset2) { Asset.create(uuid: SecureRandom.uuid)}
      let(:asset_group) { AssetGroup.create(uuid: SecureRandom.uuid)}
      it 'adds the assets to the asset group' do
        updates1.add_assets(asset_group, [asset1.uuid, asset2.uuid])
        expect{updates1.apply(step)}.to change{asset_group.assets.count}.by(2)
        .and change{Operation.count}.by(2)
      end
    end

    context 'with remove_assets' do
      let(:asset1) { Asset.create(uuid: SecureRandom.uuid)}
      let(:asset2) { Asset.create(uuid: SecureRandom.uuid)}
      let(:asset_group) { AssetGroup.create(uuid: SecureRandom.uuid)}
      it 'adds the assets to the asset group' do
        asset_group.assets << [asset1, asset2]
        updates1.remove_assets(asset_group, [asset1.uuid, asset2.uuid])
        expect{updates1.apply(step)}.to change{asset_group.assets.count}.by(-2)
        .and change{Operation.count}.by(2)
      end
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

  describe '#values_for_predicate' do
    it 'returns all the current values in the database' do
      asset = create(:asset)
      asset.facts << create(:fact, predicate: 'description', object: 'green')
      asset.facts << create(:fact, predicate: 'description', object: 'big')
      expect(updates1.values_for_predicate(asset, 'description')).to eq(['green', 'big'])
    end
    it 'returns all the values that will be added' do
      asset = create(:asset)
      updates1.add(asset, 'description', 'tall')
      updates1.add(asset, 'description', 'slim')
      expect(updates1.values_for_predicate(asset, 'description')).to eq(['tall', 'slim'])
    end
    it 'returns all the values both from the database to add' do
      asset = create(:asset)
      asset.facts << create(:fact, predicate: 'description', object: 'green')
      asset.facts << create(:fact, predicate: 'description', object: 'big')
      updates1.add(asset, 'description', 'tall')
      updates1.add(asset, 'description', 'slim')
      expect(updates1.values_for_predicate(asset, 'description')).to eq(['green', 'big', 'tall', 'slim'])
    end

    it 'does not return the values that will be removed from database' do
      asset = create(:asset)
      asset.facts << create(:fact, predicate: 'description', object: 'green')
      asset.facts << create(:fact, predicate: 'description', object: 'big')

      # These values are not in the database yet, so they won't be removed
      updates1.add(asset, 'description', 'tall')
      updates1.add(asset, 'description', 'slim')

      # This won't remove anything, as the value is not in database
      updates1.remove_where(asset, 'description', 'slim')
      updates1.remove_where(asset, 'description', 'green')

      expect(updates1.values_for_predicate(asset, 'description')).to eq(['big', 'tall', 'slim'])
    end

    it 'does not return values from other instances' do
      asset = create(:asset)
      asset.facts << create(:fact, predicate: 'description', object: 'green')

      asset2 = create(:asset)
      asset2.facts << create(:fact, predicate: 'description', object: 'blue')

      updates1.add(asset, 'description', 'tall')
      updates1.add(asset2, 'description', 'small')

      expect(updates1.values_for_predicate(asset, 'description')).to eq(['green', 'tall'])
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

  describe '#create_asset_groups' do
    it 'adds the list to the asset groups to create' do
      updates1.create_asset_groups(["?p", "?q", "?r"])
      expect(updates1.asset_groups_to_create.length).to eq(3)
    end
    it 'does not add twice the same asset' do
      updates1.create_asset_groups(["?p", "?q", "?p"])
      expect(updates1.asset_groups_to_create.length).to eq(2)
    end
    it 'does not raise error when referring to an asset not referred before' do
      expect{updates1.create_asset_groups([SecureRandom.uuid])}.not_to raise_error
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

  describe '#delete_asset_groups' do
    let(:asset_group1) { AssetGroup.create(uuid: SecureRandom.uuid)}
    let(:asset_group2) { AssetGroup.create(uuid: SecureRandom.uuid)}
    let(:asset_group3) { AssetGroup.create(uuid: SecureRandom.uuid)}
    it 'adds the list to the asset groups to destroy' do
      updates1.delete_asset_groups([asset_group1.uuid, asset_group2.uuid, asset_group3.uuid])
      expect(updates1.asset_groups_to_destroy.length).to eq(3)
    end
    it 'does not add twice the same asset' do
      updates1.delete_asset_groups([asset_group1.uuid, asset_group2.uuid, asset_group1.uuid])
      expect(updates1.asset_groups_to_destroy.length).to eq(2)
    end
    it 'raises error when referring to an asset not referred before ' do
      expect{updates1.delete_asset_groups([SecureRandom.uuid])}.to raise_error(StandardError)
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
