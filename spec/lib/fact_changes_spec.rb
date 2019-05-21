require 'rails_helper'

RSpec.describe FactChanges do
  let(:activity) { create :activity }
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
  let(:step) { create :step, activity: activity }
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
      let(:facts1) { create :fact, predicate: 'color', object: 'red'}
      let(:facts2) { create :fact, predicate: 'color', object: 'blue'}
      let(:asset3) { create(:asset, facts: [facts1]) }
      let(:asset4) { create(:asset, facts: [facts2]) }
      let(:asset_group) { create :asset_group, assets: [asset3, asset4] }
      before do
        updates1.delete_assets(asset_group.assets)
      end
      it 'does not really remove the assets' do
        expect{updates1.apply(step)}.to change{Asset.count}.by(0).and change{Operation.count}.by(2)
      end
      it 'removes the facts for the assets' do
        expect{updates1.apply(step)}.to change{asset3.facts.count}.by(-1)
          .and change{asset4.facts.count}.by(-1)
      end
      it 'detaches the assets from any groups' do
        expect{updates1.apply(step)}.to change{asset3.asset_groups.count}.by(-1)
          .and change{asset4.asset_groups.count}.by(-1)
      end
    end

    context 'with add_assets' do
      let(:asset1) { Asset.create(uuid: SecureRandom.uuid)}
      let(:asset2) { Asset.create(uuid: SecureRandom.uuid)}
      let(:asset_group) { AssetGroup.create(uuid: SecureRandom.uuid)}
      it 'adds the assets to the asset group' do
        updates1.add_assets([[asset_group, [asset1.uuid, asset2.uuid]]])
        expect{updates1.apply(step)}.to change{asset_group.assets.count}.by(2)
        .and change{Operation.count}.by(2)
      end
    end

    context 'with remove_assets' do
      let(:asset1) { Asset.create(uuid: SecureRandom.uuid)}
      let(:asset2) { Asset.create(uuid: SecureRandom.uuid)}
      let(:asset_group) { AssetGroup.create(uuid: SecureRandom.uuid)}
      it 'removes the assets to the asset group' do
        asset_group.assets << [asset1, asset2]
        updates1.remove_assets([[asset_group, [asset1.uuid, asset2.uuid]]])
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
      updates1.add_assets([[asset_group, [asset1.uuid, asset2.uuid]]])
      expect(updates1.assets_to_add.length).to eq(2)
    end
    it 'does not add twice the same asset' do
      updates1.add_assets([[asset_group, [asset1.uuid, asset1.uuid]]])
      expect(updates1.assets_to_add.length).to eq(1)
    end
    it 'raises error when referring to an asset group not referred before ' do
      expect{updates1.add_assets([[SecureRandom.uuid, [asset1.uuid, asset2.uuid]]])}.to raise_error(StandardError)
    end

  end

  describe '#remove_assets' do
    let(:asset1) { Asset.create(uuid: SecureRandom.uuid)}
    let(:asset2) { Asset.create(uuid: SecureRandom.uuid)}
    let(:asset_group) { AssetGroup.create(uuid: SecureRandom.uuid)}
    it 'adds the changes to the list of assets to add one for each asset' do
      updates1.remove_assets([[asset_group, [asset1.uuid, asset2.uuid]]])
      expect(updates1.assets_to_remove.length).to eq(2)
    end
    it 'does not add twice the same asset' do
      updates1.remove_assets([[asset_group, [asset1.uuid, asset1.uuid]]])
      expect(updates1.assets_to_remove.length).to eq(1)
    end
    it 'raises error when referring to an asset group not referred before ' do
      expect{updates1.remove_assets([[SecureRandom.uuid, [asset1.uuid, asset2.uuid]]])}.to raise_error(StandardError)
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

  describe '#build_asset_groups' do
    it 'creates a new asset group' do
      expect(FactChanges.new.build_asset_groups(["?p"]).first.kind_of?(AssetGroup)).to eq(true)
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
    context 'with create_asset_groups' do
      before do
        updates.create_asset_groups(['?pcreate', '?qcreate'])
        activity.asset_group
      end
      let(:updates) { FactChanges.new }
      it 'creates new asset groups' do
        expect{updates.apply(step)}.to change{AssetGroup.count}.by(2)
      end
      it 'adds the asset group to the activity this step belongs to' do
        expect{updates.apply(step)}.to change{activity.owned_asset_groups.count}.by(2)
      end
      it 'creates as many operations as asset groups created' do
        expect{updates.apply(step)}.to change{Operation.all.count}.by(2)
      end
      context 'when the group is created with wildcard' do
        it 'adds the wildcard as the name of the asset group' do
          updates.apply(step)
          expect(AssetGroup.find_by(name: 'pcreate')).not_to eq(nil)
          expect(AssetGroup.find_by(name: 'qcreate')).not_to eq(nil)
        end
      end
      context 'when the group is created with uuid' do
        context 'when the uuid refers to an already existing group' do
          let(:asset_group) { create :asset_group }
          let(:updates2) { FactChanges.new }
          it 'uses that uuid and does not create any group' do
            updates2.create_asset_groups([asset_group.uuid])
            expect{updates2.apply(step)}.to change{AssetGroup.count}.by(0)
          end
        end
        context 'when the uuid does not refer anything already in database' do
          let(:updates2) { FactChanges.new }
          it 'uses that uuid and does not create any group' do
            updates2.create_asset_groups([SecureRandom.uuid])
            expect{updates2.apply(step)}.to change{AssetGroup.count}.by(1)
          end
        end
      end
      context 'when the group is created with group' do
        let(:updates2) { FactChanges.new }
        let(:asset_group) { create :asset_group }
        it 'uses that group' do
          updates2.create_asset_groups([asset_group])
          expect{updates2.apply(step)}.to change{AssetGroup.count}.by(0)
        end
      end

    end
    context 'with delete_asset_groups' do
      let(:asset_group1){ create :asset_group, activity_owner: activity }
      let(:asset_group2){ create :asset_group, activity_owner: activity}
      let(:json) { { create_asset_groups: ['?p'] }.to_json }
      let(:updates) { FactChanges.new }
      before do
        updates.delete_asset_groups([asset_group1.uuid, asset_group2.uuid])
        activity.asset_group
      end
      it 'DOES NOT remove the specified asset groups' do
        expect{updates.apply(step)}.to change{AssetGroup.count}.by(0)
      end
      it 'removes the asset group from the activity' do
        expect{updates.apply(step)}.to change{activity.owned_asset_groups.count}.by(-2)
      end
      it 'creates as many operations as asset groups deleted' do
        expect{updates.apply(step)}.to change{Operation.all.count}.by(2)
      end
    end

    context 'with create_assets' do
      before do
        updates.create_assets(['?p', '?q'])
      end
      let(:updates) { FactChanges.new }
      it 'creates new assets' do
        expect{updates.apply(step)}.to change{Asset.count}.by(2)
      end
      it 'creates as many operations as assets created' do
        expect{updates.apply(step)}.to change{Operation.all.count}.by(2)
      end
    end
    context 'with delete_assets' do
      let(:asset1){ create :asset }
      let(:asset2){ create :asset}
      let(:asset_group) { create :asset_group, assets: [asset1, asset2]}
      let(:updates) { FactChanges.new }
      before do
        updates.delete_assets(asset_group.assets.map(&:uuid))
      end
      it 'does not remove the specified assets' do
        expect{updates.apply(step)}.to change{Asset.count}.by(0)
      end
      it 'does remove the assets from the asset groups' do
        expect{updates.apply(step)}.to change{asset1.asset_groups.count}.by(-1)
          .and change{asset2.asset_groups.count}.by(-1)
      end
      it 'creates as many operations as assets deleted' do
        expect{updates.apply(step)}.to change{Operation.all.count}.by(2)
      end
    end

    context 'with add_assets' do
      let(:asset_group) { create :asset_group }
      let(:assets){ 2.times.map{ create :asset } }
      let(:updates) { FactChanges.new }
      before do
        step.update_attributes(asset_group: create(:asset_group))
      end

      context 'when an asset group and a list of assets is provided' do
        before do
          updates.add_assets([[asset_group, assets]])
        end
        it 'adds the asset to the asset group' do
          expect{ updates.apply(step) }.to change{asset_group.assets.count}.by(2)
        end
        it 'adds one operation for each asset added' do
          expect{ updates.apply(step) }.to change{Operation.count}.by(2)
        end
      end
      context 'when only one list of assets is provided' do
        before do
          updates.add_assets([assets])
        end
        it 'adds the asset to the asset group of the step' do
          expect{ updates.apply(step) }.to change{step.asset_group.assets.count}.by(2)
        end
        it 'adds one operation for each asset added' do
          expect{ updates.apply(step) }.to change{Operation.count}.by(2)
        end
      end
    end

    context 'with remove_assets' do
      let(:asset_group) { create :asset_group }
      let(:assets){ 2.times.map{ create :asset } }
      let(:updates) { FactChanges.new }
      before do
        step.update_attributes(asset_group: create(:asset_group))
      end

      context 'when an asset group and a list of assets is provided' do
        before do
          asset_group.assets << assets
          updates.remove_assets([[asset_group, assets]])
        end
        it 'removes the assets from the asset group' do
          expect{ updates.apply(step) }.to change{asset_group.assets.count}.by(-2)
        end
        it 'adds one operation for each asset removed' do
          expect{ updates.apply(step) }.to change{Operation.count}.by(2)
        end
      end
      context 'when an asset group and a list of assets is provided' do
        before do
          step.asset_group.assets << assets
          updates.remove_assets([assets])
        end
        it 'removes the assets from the asset group of the step' do
          expect{ updates.apply(step) }.to change{step.asset_group.assets.count}.by(-2)
        end
        it 'adds one operation for each asset removed' do
          expect{ updates.apply(step) }.to change{Operation.count}.by(2)
        end
      end
    end
    context 'with several operations using wildcards' do
      let(:updates) { FactChanges.new }
      before do
        activity.asset_group
      end
      it 'performs all the changes specified' do
        updates.create_assets(["?p", "?q"])
        updates.add("?p", "a", "Plate")
        updates.add("?q", "a", "Plate")
        updates.create_asset_groups(["?group1"])
        updates.add_assets([["?group1", ["?p", "?q"]]])

        expect{updates.apply(step)}.to change{Asset.count}.by(2)
          .and change{AssetGroup.count}.by(1)
          .and change{AssetGroupsAsset.count}.by(2)
          .and change{activity.owned_asset_groups.count}.by(1)
        expect(activity.owned_asset_groups.last.assets.first.facts.first.object).to eq("Plate")
      end
    end
  end
end
