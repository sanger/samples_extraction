require 'rails_helper'

RSpec.describe Asset, type: :model do
  describe 'Export' do
    setup do
      facts = %Q{
        :tube1   :a                 :Tube ;
                 :location          "A1" .
        :tube2   :a                 :Tube ;
                 :location          "B1" .
        :tube3   :a                 :Tube ;
                 :location          "C1" .
        :tube4   :a                 :Tube ;
                 :location          "D1" .

        :rack1   :a                 :TubeRack ;
                 :contains          :tube1, :tube2, :tube3, :tube4 .
      }
      @assets = SupportN3::parse_facts(facts)
    end    
    context '#racking_info' do
      it 'generates an attribute object for a well' do
        @rack1 = Asset.find_by(uuid: 'rack1')
        expect(@rack1.attributes_to_update).to eq([
          {uuid: "tube1", location: "A1"},
          {uuid: "tube2", location: "B1"},
          {uuid: "tube3", location: "C1"},
          {uuid: "tube4", location: "D1"}])
      end
    end
  end
end