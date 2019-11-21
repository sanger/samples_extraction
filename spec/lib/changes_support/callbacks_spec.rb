require 'rails_helper'

RSpec.describe 'ChangesSuppport::Callbacks' do
  context 'with a FactChanges object' do
    before do
      FactChanges.clear_all_callbacks!
      FactChanges.on_change_predicate('add_facts', 'color', Proc.new{|fact, updates|
        spy_instance.my_method(fact, updates)
      })
    end


    let(:updates) { FactChanges.new }
    let(:asset) { create :asset }
    let(:step) { create :step }

    context 'when I have defined a callback on adding a property' do

      before do
      end
      context 'when I add a property that matches the condition of my callback' do
        before do
          updates.add(asset, 'color', 'Red')
        end
        context 'and then I apply my changes' do
          let(:spy_instance) { spy('callback_method')}

          it 'runs the callback defined before' do
            updates.apply(step)
            expect(spy_instance).to have_received(:my_method).with({
              asset: asset, predicate: 'color', object: 'Red', literal: true}, updates)
          end
          it 'also runs the callback again if I make another change' do
            updates.apply(step)
            updates2 = FactChanges.new
            updates2.add(asset, 'color', 'Blue')
            updates2.apply(step)
            expect(spy_instance).to have_received(:my_method).twice
          end
        end
      end
    end
  end
end
