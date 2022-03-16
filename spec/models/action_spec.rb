require 'rails_helper'
RSpec.describe Action, type: :model do
  context '#each_connected_asset' do
    let(:action) {
      create(:action, step_type: step_type,
                      predicate: 'some verb', action_type: 'something')
    }

    shared_examples 'a connector by position' do
      let(:step_type) {
        create(:step_type,
               connect_by: 'position')
      }
      it 'yields sources and destination' do
        i = 0
        action.each_connected_asset(sources, destinations) do |a, b|
          expect([a, b]).to eq(pairs_by_position[i])
          i = i + 1
        end
      end
    end
    shared_examples 'a connector of all to all' do
      let(:step_type) { create(:step_type) }
      it 'yields sources and destination' do
        i = 0
        action.each_connected_asset(sources, destinations) do |a, b|
          expect([a, b]).to eq(pairs[i])
          i = i + 1
        end
      end
    end

    context 'when there are equal number of sources and destinations' do
      let(:sources) { [:a, :b, :c] }
      let(:destinations) { [:alpha, :beta, :gamma] }
      let(:pairs_by_position) { [[:a, :alpha], [:b, :beta], [:c, :gamma]] }
      let(:pairs) {
        [
          [:a, :alpha], [:a, :beta], [:a, :gamma],
          [:b, :alpha], [:b, :beta], [:b, :gamma],
          [:c, :alpha], [:c, :beta], [:c, :gamma]
        ]
      }

      it_behaves_like 'a connector by position'
      it_behaves_like 'a connector of all to all'
    end
    context 'when there are less sources than destinations' do
      let(:sources) { [:a, :b] }
      let(:destinations) { [:alpha, :beta, :gamma] }
      let(:pairs_by_position) { [[:a, :alpha], [:b, :beta]] }
      let(:pairs) {
        [
          [:a, :alpha], [:a, :beta], [:a, :gamma],
          [:b, :alpha], [:b, :beta], [:b, :gamma]
        ]
      }
      it_behaves_like 'a connector by position'
      it_behaves_like 'a connector of all to all'
    end
    context 'when there are less destinations than sources' do
      let(:sources) { [:a, :b, :c] }
      let(:destinations) { [:alpha, :beta] }
      let(:pairs_by_position) { [[:a, :alpha], [:b, :beta]] }
      let(:pairs) {
        [
          [:a, :alpha], [:a, :beta],
          [:b, :alpha], [:b, :beta],
          [:c, :alpha], [:c, :beta]
        ]
      }
      it_behaves_like 'a connector by position'
      it_behaves_like 'a connector of all to all'
    end
  end
end
