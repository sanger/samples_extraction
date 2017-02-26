require 'rails_helper'
require 'inferences_helper'
require 'integration/inferences_data'

RSpec.describe "Inference" do

  describe '#inference' do
    describe '#parse_facts' do
      it 'creates assets from a N3 definition' do
        code = %{
          :tube1 :relates :tube2 .
          :tube2 :name """a name""" .
          :tube2 :volume """17""" .
        }

        obtained_assets = SupportN3::parse_facts(code)

        tube1 = FactoryGirl.create(:asset, :name => 'tube1')
        tube2 = FactoryGirl.create(:asset, :name => 'tube2')
        tube3 = FactoryGirl.create(:asset)
        tube4 = FactoryGirl.create(:asset, :name => 'tube4')
        tube5 = FactoryGirl.create(:asset, :name => 'tube2')

        tube1.facts << FactoryGirl.create(:fact, {:predicate => 'relates', :object_asset => tube2})
        tube4.facts << FactoryGirl.create(:fact, {:predicate => 'relates', :object_asset => tube2})
        tube2.facts << FactoryGirl.create(:fact, {:predicate => 'name', :object => 'a name'})
        tube2.facts << FactoryGirl.create(:fact, {:predicate => 'volume', :object => '17'})
        tube5.facts << FactoryGirl.create(:fact, {:predicate => 'volume', :object => '17'})

        assets_are_equal([tube1], [tube1])

        assets_are_equal([tube1, tube2], obtained_assets)
        assets_are_different([tube3, tube2], obtained_assets)
        assets_are_different([tube4, tube2], obtained_assets)
        assets_are_different([tube1, tube5], obtained_assets)
        assets_are_equal([tube2,tube1], [tube1, tube2])

        assets_are_equal([tube1, tube1, tube2], [tube1, tube2])
      end
    end

    describe '#inferences' do
      inferences_data.each do |data|
        if data[:it]
          tags = data[:tags] ? data[:tags] : {}
          it data[:it], tags do
            check_inference(data[:rule], data[:inputs], data[:outputs])
          end
        else
          xit data[:xit] do
            check_inference(data[:rule], data[:inputs], data[:outputs])
          end
        end
      end
    end

  end
end