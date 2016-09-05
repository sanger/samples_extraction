#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'pry'

class SequencescapeClient
  @purposes=nil

  def self.api_connection_options
    {
      :namespace     => 'SamplesExtraction',
      :url           => 'http://localhost:3000/api/1/',
      :authorisation => 'development'
    }
  end

  def self.api
    @api ||= Sequencescape::Api.new(self.api_connection_options)
  end

  def self.find_by_uuid(uuid)
    api.plate.find(uuid)
  rescue Sequencescape::Api::ResourceNotFound => exception
    return nil
  end

  def self.update(instance, attrs)
  end

  def self.purpose_by_name(name)
    api.plate_purpose.all.select{|p| p.name===name}.first
  end

  def self.create(purpose_name, attrs)
    purpose_by_name(purpose_name).plates.create!(attrs)
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
