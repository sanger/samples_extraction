#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'pry'
require 'sequencescape-api'
require 'sequencescape'

class SequencescapeClient
  @purposes=nil

  def self.api_connection_options
    {
      :namespace     => 'SamplesExtraction',
      :url           => 'http://localhost:3000/api/1/',
      :authorisation => 'development'
    }
  end

  def self.client
    @client ||= Sequencescape::Api.new(self.api_connection_options)
  end

  def self.find_by_uuid(uuid)
    client.plate.find(uuid)
  rescue Sequencescape::Api::ResourceNotFound => exception
    return nil
  end

  def self.update_asset_attributes(instance, attrs)
    binding.pry
    instance.update_asset_attributes(attrs)
    #instance.wells.zip(attrs.to_a).
  end

  def self.update_wells(instance, attrs)
    instance.wells.each do |well|
      attrs.to_a.select do |well_attr|
        well_attr.all? do |k,v|
          well.send(k) === v if well.respond_to?(k)
        end
      end.first.tap do |well_attr|
        well.update_attributes!(well_attr)
      end
    end
  end

  def self.purpose_by_name(name)
    client.plate_purpose.all.select{|p| p.name===name}.first
  end

  def self.create_plate(purpose_name, attrs)
    attrs = {}
    purpose = purpose_by_name(purpose_name) || purpose_by_name('Stock Plate')
    purpose.plates.create!(attrs)
  end

  def self.find_by_barcode(barcode)
    asset = Asset.find_by_barcode(barcode)
    unless asset
      uuid = "a06fad30-54c6-11e6-b689-44fb42fffe72"
      remote_asset = client.search.find(uuid).first(:barcode => barcode)
      asset = Asset.create(:barcode => barcode)
      asset.facts << Fact.create(:predicate => 'a', :object => remote_asset.class.to_s.gsub(/Sequencescape::/,''))
      asset.facts << Fact.create(:predicate => 'is', :object => 'NotStarted')
    end
    asset
  end
end

#plate = SequencescapeClient.create("Stock Plate", {})
#plate = SequencescapeClient.find_by_uuid(plate["uuid"])
#plate = SequencescapeClient.find_by_uuid("111")

#SequencescapeClient::PlateCreation.create(
#  {
#     :plate_creation =>{
#       :user => 'b55f7a90-54c6-11e6-9ffd-44fb42fffe72',
#       :parent => nil,
#       :child_purpose => '8a4da160-54c6-11e6-b689-44fb42fffe72'
#     }
#   }.to_json
# )
