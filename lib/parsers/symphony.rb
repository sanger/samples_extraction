require 'pry'
module Parsers
  class Symphony
    attr_reader :doc
    def initialize(str)
      @doc = Nokogiri::XML(str)
    end

    def self.valid_for?(str)
      return Nokogiri::XML(str).xpath("Rack").count == 1
    end

    def to_assets
      @doc.xpath("/Rack//RackPosition").map do |rack_position|
        facts = ["SampleId", "PositionName", "TotalVolumeInUl"].map do |name|
          value = rack_position.at_xpath(name).text
          if name == "PositionName"
            value = value.gsub!(':','')
          end
          Fact.new(:predicate => 'Symphony:'+name,
            :object => value
            )
        end
        asset = Asset.new
        asset.facts << facts
        asset
      end
    end

    def add_assets(asset)
      #to_assets.each do |a|
      #  asset.facts << Fact.create(:predicate => "Symphony:RackPosition", :object_asset_id => a.id)
      #end
      #asset.reasoning!
      connect_tubes!(asset)
    end

    def location_to_index(location)
      letter, num = location[0], location[1]
      (('A'..'F').find_index(location[0]) * 12) + (location[1].to_i - 1)
    end

    def predicated_with(facts, predicate)
      facts.select{|f| f.predicate == predicate}
    end

    def connect_tubes!(rack)
      tubes = predicated_with(rack.facts,'contains').map{|f| f.object_asset}
      to_assets.each do |position_asset|
        rack_position_facts = position_asset.facts
        posName = predicated_with(rack_position_facts, 'Symphony:PositionName').first.object
        if posName
          tube = tubes.select{|tube| tube.facts.with_fact('location', posName).count!=0}.first
          if tube
            tube.facts << rack_position_facts
            tube.facts << predicated_with(rack_position_facts, 'Symphony:TotalVolumeInUl').map do |f|
              f2 = f.clone
              f2.predicate = 'measured_volume'
              f2
            end
          end
        end
      end
    end

  end
end
