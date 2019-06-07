require 'rails_helper'

RSpec.describe 'Asset::Export' do
  describe 'Export' do
    context '#racking_info' do
      it 'generates an attribute object for a well' do
        facts = %Q{
          :s1 :a :SampleTube .
          :s2 :a :SampleTube .
          :s3 :a :SampleTube .
          :s4 :a :SampleTube .
          :tube1   :a                 :Tube ;
                   :location          "A1" ;
                   :sample_tube       :s1 .
          :tube2   :a                 :Tube ;
                   :location          "B1" ;
                   :sample_tube       :s2 .
          :tube3   :a                 :Tube ;
                   :location          "C1" ;
                   :sample_tube       :s3 .
          :tube4   :a                 :Tube ;
                   :location          "D1" ;
                   :sample_tube       :s4 .

          :rack1   :a                 :TubeRack ;
                   :contains          :tube1, :tube2, :tube3, :tube4 .
        }
        @assets = SupportN3::parse_facts(facts)

        @rack1 = Asset.find_by(uuid: 'rack1')
        expect(@rack1.attributes_to_update).to eq([
          {sample_tube_uuid: "s1", location: "A1"},
          {sample_tube_uuid: "s2", location: "B1"},
          {sample_tube_uuid: "s3", location: "C1"},
          {sample_tube_uuid: "s4", location: "D1"}])
      end

    end
    context '#to_sequencescape_location' do
      it 'converts SE locations to sequencescape' do
        a = create :asset
        expect(a.to_sequencescape_location("A01")).to eq("A1")
        expect(a.to_sequencescape_location("F01")).to eq("F1")
        expect(a.to_sequencescape_location("A1")).to eq("A1")
        expect(a.to_sequencescape_location("E1")).to eq("E1")
      end
    end
    context '#attributes_to_update' do
      it 'can convert location to Sequencescape location format' do
        %Q{
          I have a tube rack that contains 4 tubes with names tube1, tube2,
          tube3 and tube4.
          tube1 is in location A01, tube2 in B01, tube3 in C01 and tube4 in D1.
          Each tube has a sample tube inside, with names s1, s2, s3 and s4.
        }
        facts = %Q{
          :s1 :a :SampleTube .
          :s2 :a :SampleTube .
          :s3 :a :SampleTube .
          :s4 :a :SampleTube .
          :rack2   :a                 :TubeRack ;
                   :contains          :tube1, :tube2, :tube3, :tube4 .

          :tube1   :a                 :Tube ;
                   :location          "A01" ;
                   :sample_tube       :s1 .
          :tube2   :a                 :Tube ;
                   :location          "B01" ;
                   :sample_tube       :s2 .
          :tube3   :a                 :Tube ;
                   :location          "C01" ;
                   :sample_tube       :s3 .
          :tube4   :a                 :Tube ;
                   :location          "D1" ;
                   :sample_tube       :s4 .
        }
        @assets = SupportN3::parse_facts(facts)
        @rack2 = Asset.find_by(uuid: 'rack2')
        expect(@rack2.attributes_to_update).to eq([
          {sample_tube_uuid: "s1", location: "A1"},
          {sample_tube_uuid: "s2", location: "B1"},
          {sample_tube_uuid: "s3", location: "C1"},
          {sample_tube_uuid: "s4", location: "D1"}])
      end
      it 'generates the attributes when the locations are not duplicated' do
        facts = %Q{
          :s1 :a :SampleTube .
          :s2 :a :SampleTube .
          :s3 :a :SampleTube .
          :s4 :a :SampleTube .
          :rack2   :a                 :TubeRack ;
                   :contains          :tube1, :tube2, :tube3, :tube4 .

          :tube1   :a                 :Tube ;
                   :location          "A1" ;
                   :sample_tube       :s1 .
          :tube2   :a                 :Tube ;
                   :location          "B1" ;
                   :sample_tube       :s2 .
          :tube3   :a                 :Tube ;
                   :location          "C1" ;
                   :sample_tube       :s3 .
          :tube4   :a                 :Tube ;
                   :location          "D1" ;
                   :sample_tube       :s4 .
        }
        @assets = SupportN3::parse_facts(facts)
        @rack2 = Asset.find_by(uuid: 'rack2')
        expect(@rack2.attributes_to_update).to eq([
          {sample_tube_uuid: "s1", location: "A1"},
          {sample_tube_uuid: "s2", location: "B1"},
          {sample_tube_uuid: "s3", location: "C1"},
          {sample_tube_uuid: "s4", location: "D1"}])
      end

      it 'fails when trying to generate attributes when the locations are duplicated' do
        facts = %Q{
          :s1 :a :SampleTube .
          :s2 :a :SampleTube .
          :s3 :a :SampleTube .
          :s4 :a :SampleTube .
          :rack2   :a                 :TubeRack ;
                   :contains          :tube1, :tube2, :tube3, :tube4 .
          :tube1   :a                 :Tube ;
                   :location          "A1" ;
                   :sample_tube       :s1 .
          :tube2   :a                 :Tube ;
                   :location          "B1" ;
                   :sample_tube       :s2 .
          :tube3   :a                 :Tube ;
                   :location          "A1" ;
                   :sample_tube       :s3 .
          :tube4   :a                 :Tube ;
                   :location          "B1" ;
                   :sample_tube       :s4 .
        }
        @assets = SupportN3::parse_facts(facts)
        @rack2 = Asset.find_by(uuid: 'rack2')
        expect{@rack2.attributes_to_update}.to raise_exception Asset::Export::DuplicateLocations
      end
    end
  end
end
