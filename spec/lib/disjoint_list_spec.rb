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

  describe '#add_to_list_keep_unique' do
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
end
