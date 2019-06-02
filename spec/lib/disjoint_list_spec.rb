require 'rails_helper'
require 'disjoint_list'

RSpec.describe 'DisjointList' do
  let(:facts_to_add) { [] }
  let(:facts_to_destroy) { [] }
  let(:list) { DisjointList.new(facts_to_add) }

  def create_linked_relation(num_elements, initial_values=nil)
    num_elements.times.map.reduce([]) do |memo, i|
      initial_value = []
      initial_value = initial_values[i] if initial_values && initial_values.length < i
      list = DisjointList.new(initial_value)
      memo[i-1].set_opposite_disjoint(list) if i!=0
      memo.push(list)
    end
  end

  describe '#initialize' do
    it 'adds the elements of the list and caches info' do
      expect(DisjointList.new([1,2,3]).enabled_ids.keys.length).to eq(3)
    end
  end

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
    it 'returns the disjoint list' do
      expect(list.add(elem)).to eq(list)
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
      .and change{list.enabled_ids.keys.length}.by(1)
    end
    it 'does not add the element again if it is already present' do
      list.add(elem)
      expect{
        list.add(elem)
      }.to change{facts_to_add.length}.by(0)
      .and change{list.length}.by(0)
    end
    it 'disables the element from the list if is present in the opposite list' do
      list.set_opposite_disjoint(list2)
      list2.set_opposite_disjoint(list)

      list.add(elem)

      expect(list.include?(elem)).to eq(true)
      expect(list2.include?(elem)).to eq(false)

    end
  end
  describe '#remove' do
    let(:elem) { {} }

    it 'removes the element with id from the list' do
      list.add(elem)
      expect(list.length).to eq(1)
      expect{list.remove(elem)}.to change{list.length}.by(-1)
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

    it 'removes all elements present in the opposite list' do
      list << [1,2,3]
      list2 << [2]
      expect(list.to_a).to eq([1,2,3])
      expect(list2.to_a).to eq([2])
      expect{list.set_opposite_disjoint(list2)}.to change{list.to_a}.from([1,2,3]).to([1,3])
    end

    it 'does not remove anything from the opposite list' do
      list.add(elem)
      list2.add(elem)

      expect{list.set_opposite_disjoint(list2)}.to change{list.include?(elem)}.from(true).to(false)
      .and change{list.length}.from(1).to(0)
      expect(list.to_a).to eq([])
      expect(list2.to_a).to eq([elem])
    end

    it 'disables elements because of the opposite disjoint' do
      list.set_opposite_disjoint(list2)
      expect{list2.add(elem2)}.to change{list2.include?(elem2)}.from(false).to(true)
      expect{list.add(elem2)}.to change{list2.include?(elem2)}.from(true).to(false)
      expect(list.include?(elem2)).to eq(false)
    end

    context 'on a linked relation with disjoint lists' do
      let(:lists) { create_linked_relation(5) }

      it 'does not add elements disabled that belong to my direct opposite list' do
        lists[0] << []
        lists[1] << [1]
        lists[2] << []
        lists[3] << []
        lists[4] << []

        lists[0] << [1]

        expect(lists[0].to_a).to eq([])
        expect(lists[1].to_a).to eq([])
      end

      it 'claims elements cascades all changes until the last element' do
        lists[0] << []
        lists[1] << []
        lists[2] << []
        lists[3] << []
        lists[4] << [1,2,3,4,5]

        lists[0] << [1,2,3,4,5]

        expect(lists[0].to_a).to eq([1,2,3,4,5])
        expect(lists[1].to_a).to eq([])
        expect(lists[2].to_a).to eq([])
        expect(lists[3].to_a).to eq([])
        expect(lists[4].to_a).to eq([])

        expect(lists[1].disabled_values).to eq([1,2,3,4,5])
        expect(lists[2].disabled_values).to eq([1,2,3,4,5])
        expect(lists[3].disabled_values).to eq([1,2,3,4,5])
        expect(lists[4].disabled_values).to eq([1,2,3,4,5])
      end

      it 'does not affect previous lists' do
        lists[0] << [1,2,3,4,5]
        lists[1] << []
        lists[2] << []
        lists[3] << []
        lists[4] << []

        lists[2] << [1,2,3,4,5]

        expect(lists[0].to_a).to eq([1,2,3,4,5])
        expect(lists[1].to_a).to eq([])
        expect(lists[2].to_a).to eq([1,2,3,4,5])
        expect(lists[3].to_a).to eq([])
        expect(lists[4].to_a).to eq([])
      end
      it 'affects the next lists in the chain' do
        lists[0] << [1,2,3,4,5]
        lists[1] << []
        lists[2] << []
        lists[3] << []
        lists[4] << [6,7,8,9]

        lists[2] << [1,2,3,4,5,6,7,8,9]
        expect(lists[0].to_a).to eq([1,2,3,4,5])
        expect(lists[1].to_a).to eq([])
        expect(lists[2].to_a).to eq([1,2,3,4,5,6,7,8,9])
        expect(lists[3].to_a).to eq([])
        expect(lists[4].to_a).to eq([])
      end
      it 'affects the previous elements if there is a cycle in the chain' do
        lists[4].set_opposite_disjoint(lists[0])
        lists[0] << [1,2,3,4,5]
        lists[1] << []
        lists[2] << []
        lists[3] << []
        lists[4] << []

        lists[4] << [1,2,3,4,5]

        expect(lists[0].to_a).to eq([])
        expect(lists[1].to_a).to eq([])
        expect(lists[2].to_a).to eq([])
        expect(lists[3].to_a).to eq([])
        expect(lists[4].to_a).to eq([])
      end
    end
  end

  describe '#set_mutual_disjoint' do
    let(:list2) { DisjointList.new(facts_to_destroy) }
    before do
      list.set_mutual_disjoint(list2)
    end
    it 'removes the element if already present in my opposite list' do
      list << 'spiderman'
      list2 << 'superman'
      expect(list.to_a).to eq(['spiderman'])
      expect(list2.to_a).to eq(['superman'])
      list2 << 'spiderman'
      expect(list.to_a).to eq([])
      expect(list2.to_a).to eq(['superman'])
    end
  end

  describe '#include?' do
    let(:elem) { {} }
    it 'returns true if the element was already added' do
      expect{list.add(elem)}.to change{list.include?(elem)}.from(false).to(true)
    end
    it 'returns false if the element is not on the list' do
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


    context 'with mutual disjoint' do
      before do
        disjoint1.set_mutual_disjoint(disjoint2)
        disjoint3.set_mutual_disjoint(disjoint4)
      end

      it 'disables an element when adding it in my instance and removing it in the merged object' do
        disjoint1 << 'green'
        disjoint4 << 'green'

        expect{disjoint1.merge(disjoint3)}.to change{disjoint1.length}.by(-1)
      end

      it 'merges from different objects' do
        d1 = DisjointList.new([1])
        d2 = DisjointList.new([2])
        d3 = DisjointList.new([3])

        d1.merge(d2).merge(d3)

        expect(d1.to_a).to eq([1,2,3])
      end

      it 'merges from different objects that have mutual disjoint' do
        d1 = DisjointList.new([1])
        d2 = DisjointList.new([2])
        d3 = DisjointList.new([3])

        o1 = DisjointList.new([4])
        o2 = DisjointList.new([5])
        o3 = DisjointList.new([6])

        d1.set_mutual_disjoint(o1)
        d2.set_mutual_disjoint(o2)
        d3.set_mutual_disjoint(o3)

        d1.merge(d2).merge(d3)

        expect(d1.to_a).to eq([1,2,3])
      end

      it 'can disable elements with every merge' do
        d1 = DisjointList.new([1,2,3])
        d2 = DisjointList.new([4])
        d3 = DisjointList.new([5])

        o1 = DisjointList.new([])
        o2 = DisjointList.new([1,2])
        o3 = DisjointList.new([3])

        d1.set_mutual_disjoint(o1)
        d2.set_mutual_disjoint(o2)
        d3.set_mutual_disjoint(o3)

        d1.merge(d2).merge(d3)

        expect(d1.to_a).to eq([4,5])

      end

      it 'does not re-enable elements after merge' do
        d1 = DisjointList.new([1,2,3])
        d2 = DisjointList.new([4])
        d3 = DisjointList.new([1,2])

        o1 = DisjointList.new([])
        o2 = DisjointList.new([1,2])
        o3 = DisjointList.new([3])

        d1.set_mutual_disjoint(o1)
        d2.set_mutual_disjoint(o2)
        d3.set_mutual_disjoint(o3)

        d1.merge(d2)
        expect(d1.to_a).to eq([3,4])
        expect(d1.enabled_values.sort).to eq([3,4])
        expect(d1.disabled_values.sort).to eq([1,2])
        d1.merge(d3)
        expect(d1.to_a).to eq([4])
      end

      it 'merges the information removing values from the merged opposite disjoint list' do
        disjoint1 << ['green', 'yellow']
        disjoint2 << ['white', 'red']
        disjoint3 << ['white', 'blue']
        disjoint4 << ['green', 'black']

        disjoint1.merge(disjoint3)

        expect(disjoint1.to_a).to eq(['yellow', 'blue'])
      end

      context 'when merging a chain of objects' do
        let(:winners) { 6.times.map{DisjointList.new([])} }
        let(:losers) { 6.times.map{DisjointList.new([])} }
        let(:list) { winners.zip(losers).map{|l|
          l[0].set_mutual_disjoint(l[1])
          {winner: l[0], loser: l[1]}}
        }

        it 'keeps track of all restrictions until the final list' do
          list[0][:winner] << 'Manchester City'
          list[0][:loser] << 'Tottenham'
          list[1][:winner] << 'Liverpool'
          list[1][:loser] << 'Porto'
          list[2][:winner] << 'Ajax'
          list[2][:loser] << 'Tottenham'
          list[3][:winner] << 'Barcelona'
          list[3][:loser] << 'Liverpool'
          list[4][:winner] << 'Liverpool'
          list[4][:loser] << 'Barcelona'
          list[5][:winner] << 'Tottenham'
          list[5][:loser] << 'Ajax'

          winners = 6.times.map.reduce(DisjointList.new([])) do |memo, i|
            memo.merge(list[i][:winner])
            memo
          end
          expect(winners.to_a.sort).to eq(['Manchester City'])

        end
      end
    end

    context 'when this object and the merged one have all an opposite disjoint' do
      before do
        disjoint1.set_opposite_disjoint(disjoint2)
        disjoint3.set_opposite_disjoint(disjoint4)
      end

      it 'adds all elements in both lists if no restrictions are found' do
        disjoint1 << 'green'
        disjoint3 << 'blue'
        expect{disjoint1.merge(disjoint3)}.to change{disjoint1.to_a}.from(['green']).to(['green', 'blue'])
      end

      it 'does not add same element twice' do
        disjoint1 << ['green', 'red', 'white']
        disjoint3 << ['blue', 'red', 'white']
        expect{disjoint1.merge(disjoint3)}.to change{
          disjoint1.to_a.sort}.from(['green', 'red', 'white']).to(['blue', 'green', 'red', 'white'])
      end


      it 'merges the information of disjoint lists keeping duplicates unique' do
        disjoint1 << ['green', 'yellow']
        disjoint2 << ['paris', 'london', 'rome']
        disjoint3 << ['white', 'green', 'yellow']
        disjoint4 << ['barcelona', 'rome', 'lisbon']

        disjoint1.merge(disjoint3)

        expect(disjoint1.to_a).to eq(['green', 'yellow', 'white'])
      end

    end
  end
end
