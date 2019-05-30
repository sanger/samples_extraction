require 'rails_helper'
require 'disjoint_list'

RSpec.describe 'DisjointList' do
  let(:facts_to_add) { [] }
  let(:facts_to_destroy) { [] }
  let(:list) { DisjointList.new(facts_to_add) }

  describe '#sum_function_for' do
    it 'generates a sum function for the string provided' do
      expect(list.sum_function_for("123")).to eq(list.sum_function_for(123.to_s))
    end
    it 'always generates the same value for the same input' do
      expect(list.sum_function_for("abcdef")).to eq(list.sum_function_for("abcdef"))
    end
    it 'does not generate the same value for different inputs' do
      expect(list.sum_function_for("abcdef")).not_to eq(list.sum_function_for("ABCDEF"))
    end
  end

  describe '#unique_id_for_element' do
    it 'does not generate the same value for different inputs' do
      expect(list.unique_id_for_element("abcdef")).not_to eq(list.unique_id_for_element("ABCDEF"))
    end

    it 'always generates the same value for the same input' do
      expect(list.unique_id_for_element("abcdef")).to eq(list.unique_id_for_element("abcdef"))
    end
    it 'can generate an id for arrays' do
      expect(list.unique_id_for_element(["1","2", "3"])).to eq(list.unique_id_for_element([1,2,3]))
    end
    it 'can generate an id for hash' do
      expect(list.unique_id_for_element({a: 1, b: 2, c: 3})).to eq(list.unique_id_for_element({a: "1", b: "2", c: "3"}))
    end
    it 'can generate an id for ActiveRecord' do
      fact1 = create(:fact, predicate: 'p', object: 'v')
      fact2 = create(:fact, predicate: 'p', object: 'v')
      expect(list.unique_id_for_element(fact1)).not_to eq(list.unique_id_for_element(fact2))
      expect(list.unique_id_for_element(fact1)).to eq(list.unique_id_for_element(fact1))
    end
    it 'can generate same id for different copies of the same ActiveRecord' do
      fact1 = create(:fact, predicate: 'p', object: 'v')
      f1 = Fact.where(predicate: 'p', object: 'v').first
      f2 = Fact.where(predicate: 'p').first
      expect(list.unique_id_for_element(f1)).to eq(list.unique_id_for_element(f2))
    end
    it 'can generate same id for different instances of the same model if they have the same uuid' do
      uuid = SecureRandom.uuid
      asset1 = create(:asset, uuid: uuid)
      asset2 = create(:asset, uuid: uuid)
      expect(list.unique_id_for_element(asset1)).to eq(list.unique_id_for_element(asset2))
    end
    it 'can generate an id for a relation' do
      fact1 = create(:fact, predicate: 'p', object: 'v')
      fact2 = create(:fact, predicate: 'r', object: 's')
      f1 = Fact.where(predicate: 'p', object: 'v')
      f2 = Fact.where(predicate: 'p')
      f3 = Fact.where(predicate: 'r')
      expect(list.unique_id_for_element(f1)).to eq(list.unique_id_for_element(f2))
      expect(list.unique_id_for_element(f1)).not_to eq(list.unique_id_for_element(f3))
    end
    it 'can generate ids for basic datatypes converting to string' do
      expect(list.unique_id_for_element(1)).to eq(list.unique_id_for_element("1"))
      expect(list.unique_id_for_element(true)).to eq(list.unique_id_for_element("true"))
      expect(list.unique_id_for_element(true)).not_to eq(list.unique_id_for_element(false))
    end
    it 'does not enter in infinite loop' do
      obj = {a: 1, b: { c: nil } }
      obj[:b][:c] = obj
      expect{list.unique_id_for_element(obj)}.not_to raise_error
    end
  end

  describe '#add' do
    let(:elem) { {} }
    let(:list2) { DisjointList.new(facts_to_destroy) }
    before do
      list.set_opposite_disjoint(list2)
    end
    it 'adds the element when is not present in any of the lists' do
      expect{
        list.add(elem)
      }.to change{facts_to_add.length}.by(1)
      .and change{list.length}.by(1)
    end
    it 'caches values for performance (unique id, instance, added ids)' do
      expect{
        list.add(elem)
      }.to change{list.cached_unique_ids.keys.length}.by(1)
      .and change{list.cached_instances_by_unique_id.keys.length}.by(1)
      .and change{list.already_added_ids.keys.length}.by(1)
    end
    it 'does not add the element again if it is already present' do
      list.add(elem)
      expect{
        list.add(elem)
      }.to change{facts_to_add.length}.by(0)
      .and change{list.length}.by(0)
    end
    it 'removes the element from the list if is present in the opposite list' do
      list.set_opposite_disjoint(list2)
      list2.set_opposite_disjoint(list)

      list.add(elem)

      expect{
        list2.add(elem)
      }.to change{facts_to_add.length}.by(-1)
      .and change{facts_to_destroy.length}.by(0)
      .and change{list2.length}.by(0)
    end
  end
  describe '#remove' do
    let(:elem) { {} }

    it 'removes the element from the list' do
      list.add(elem)
      expect(list.length).to eq(1)
      expect{list.remove(elem)}.to change{list.length}.by(-1)
    end
    it 'cleans the cache for the element' do
      list.add(elem)
      expect(list.length).to eq(1)
      expect{list.remove(elem)}.to change{list.cached_instances_by_unique_id.keys.length}.by(-1)
      .and change{list.already_added_ids.keys.length}.by(-1)
    end
  end
  describe '#set_opposite_disjoint' do
    let(:elem) { {} }
    let(:elem2) { 'another value' }
    let(:list2) { DisjointList.new(facts_to_destroy) }

    it 'sets up the list as opposite list' do
      list.set_opposite_disjoint(list2)
      expect(list.opposite_disjoint).to eq(list2)
    end

    it 'performs a recheck operation when opposite already contains data' do
      list.add(elem)
      list2.add(elem)

      expect{list.set_opposite_disjoint(list2)}.to change{list.length}.by(-1)
      list.add(elem2)
      list2.add(elem2)

      expect(list.length).to eq(1)
      expect(list2.length).to eq(2)

      expect{list2.set_opposite_disjoint(list)}.to change{list2.length}.by(-1)
    end
  end
  describe '#include?' do
    let(:elem) { {} }
    it 'returns true if the element was already added' do
      expect{list.add(elem)}.to change{list.include?(elem)}.from(false).to(true)
    end
    it 'returns false if the element was not on the list' do
      expect(list.include?(elem)).to eq(false)
      list.add(elem)
      expect{list.remove(elem)}.to change{list.include?(elem)}.from(true).to(false)
    end
  end

  describe '#merge' do
    let(:disjoint1) { DisjointList.new([])}
    let(:disjoint2) { DisjointList.new([])}
    let(:disjoint3) { DisjointList.new([])}
    let(:disjoint4) { DisjointList.new([])}

    let(:list2) { DisjointList.new(facts_to_destroy) }

    it 'merges the information of disjoint lists keeping duplicates unique' do
      disjoint1.set_opposite_disjoint(disjoint2)
      disjoint3.set_opposite_disjoint(disjoint4)

      disjoint1 << ['green', 'yellow']
      disjoint2 << ['paris', 'london', 'rome']
      disjoint3 << ['white', 'green', 'yellow']
      disjoint4 << ['barcelona', 'rome', 'lisbon']

      disjoint1.merge(disjoint3)

      expect(disjoint1.to_a).to eq(['green', 'yellow', 'white'])
    end

    it 'merges the information removing values from the merged opposite disjoint list' do
      disjoint1.set_opposite_disjoint(disjoint2)
      disjoint3.set_opposite_disjoint(disjoint4)

      disjoint1 << ['green', 'yellow']
      disjoint2 << ['white', 'red']
      disjoint3 << ['white', 'blue']
      disjoint4 << ['green', 'black']

      disjoint1.merge(disjoint3)

      expect(disjoint1.to_a).to eq(['yellow', 'blue'])
    end
  end
end
