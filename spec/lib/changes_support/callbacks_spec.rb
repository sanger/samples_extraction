require 'rails_helper'

RSpec.describe 'ChangesSuppport::Callbacks' do
  context 'with a FactChanges object' do
    before do
      FactChanges.clear_all_callbacks!
      FactChanges.on_change_predicate('add_facts', 'color', Proc.new{|fact, updates, step|
        spy_instance.my_method(fact, updates, step)
      })
      FactChanges.on_keep_predicate('test', Proc.new{|fact, updates, step|
        spy_instance2.my_method(fact, updates, step)
      })

    end


    let(:updates) { FactChanges.new }
    let(:asset) { create :asset }
    let(:step) { create :step }

    context 'when I have defined a callback on adding a property' do

      context 'when I add a property that matches the condition of my callback' do
        before do
          updates.add(asset, 'color', 'Red')
        end
        context 'and then I apply my changes' do
          let(:spy_instance) { spy('callback_method')}
          let(:spy_instance2) { spy('callback_method')}

          it 'runs the callback defined before' do
            updates.apply(step)
            expect(spy_instance).to have_received(:my_method).with({
              asset: asset, predicate: 'color', object: 'Red', literal: true}, updates, step)
          end
          it 'also runs the callback again if I change using other object' do
            updates.apply(step)
            updates2 = FactChanges.new
            updates2.add(asset, 'color', 'Blue')
            updates2.apply(step)
            expect(spy_instance).to have_received(:my_method).twice
          end

          it 'runs as many times as the event happens' do
            updates.add(asset, 'color', 'Green')
            updates.add(asset, 'name', 'Hulk')
            updates.add(asset, 'is', 'Not happy')
            updates.add(asset, 'color', 'Yellow')
            updates.add(asset, 'is', 'Angry')
            updates.apply(step)
            expect(spy_instance).to have_received(:my_method).with({
              asset: asset, predicate: 'color', object: 'Green', literal: true}, updates, step).exactly(1).times
            expect(spy_instance).to have_received(:my_method).with({
              asset: asset, predicate: 'color', object: 'Red', literal: true}, updates, step).exactly(1).times
            expect(spy_instance).to have_received(:my_method).with({
              asset: asset, predicate: 'color', object: 'Yellow', literal: true}, updates, step).exactly(1).times
            expect(spy_instance).to have_received(:my_method).exactly(3).times

          end
        end
      end
    end
    context 'when I have defined a callback on keeping a property' do
      let(:spy_instance) { spy('callback_method')}
      let(:spy_instance2) { spy('callback_method')}

      context 'when the asset is not in the asset group of the step' do
        it 'does nothing' do
          updates.apply(step)
          expect(spy_instance2).not_to have_received(:my_method)
        end
      end
      context 'when the asset is in the asset group used by the step' do
        let(:group) { create :asset_group, assets: [asset]}
        before do
          step.update_attributes(asset_group: group)
        end

        context 'when my asset does not have the property' do
          context 'when I apply my changes' do
            it 'does nothing' do
              updates.apply(step)
              expect(spy_instance2).not_to have_received(:my_method)
            end
          end
          context 'when I add the property and apply changes' do
            before do
              updates.add(asset, 'test', 'some value')
            end
            it 'does nothing' do
              updates.apply(step)
              expect(spy_instance2).not_to have_received(:my_method)
            end
          end
        end

        context 'when my asset has the property already' do
          let(:fact) { create(:fact, predicate: 'test', object: 'some value') }
          before do
            asset.facts << fact
          end
          context 'when I apply my changes' do
            it 'runs the callback defined before' do
              updates.apply(step)
              expect(spy_instance2).to have_received(:my_method).with(fact, updates, step)
            end
            it 'also runs the callback again if I keep the property' do
              updates.apply(step)
              updates2 = FactChanges.new
              updates2.add(asset, 'color', 'Blue')
              updates2.apply(step)
              expect(spy_instance2).to have_received(:my_method).twice
            end

            it 'runs as many times as the update is applied' do
              updates.apply(step)
              updates.apply(step)
              updates.apply(step)
              expect(spy_instance2).to have_received(:my_method).with(fact, updates, step).exactly(3).times
            end

            it 'does not run when the property disappears' do
              updates.remove(fact)
              updates.apply(step)
              expect(spy_instance2).not_to have_received(:my_method)
            end
          end
        end
      end

    end
  end
end
