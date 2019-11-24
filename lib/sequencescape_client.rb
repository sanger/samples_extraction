#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'pry'
require 'sequencescape-api'
require 'sequencescape'

require 'sequencescape_client_v2'

class SequencescapeClient
  RESOURCES = [
      SequencescapeClientV2::Plate,
      SequencescapeClientV2::Tube,
      SequencescapeClientV2::Well
  ]

  @purposes=nil

  def self.api_connection_options
    {
      :namespace     => 'SamplesExtraction',
      :url           => Rails.configuration.ss_uri,
      :authorisation => Rails.configuration.ss_authorisation,
      :read_timeout  => 60
    }
  end

  def self.client
    @client ||= Sequencescape::Api.new(self.api_connection_options)
  end

  def self.version_1_find_by_uuid(uuid, type=:plate)
    client.send(type).find(uuid)
  rescue Sequencescape::Api::ResourceNotFound => exception
    return nil
  end

  def self.update_extraction_attributes(instance, attrs, username='test')
    instance.extraction_attributes.create!(:attributes_update => attrs, :created_by => username)
  end

  def self.purpose_by_name(name)
    client.plate_purpose.all.select{|p| p.name===name}.first
  end

  def self.create_plate(purpose_name, attrs)
    attrs = {}
    purpose = purpose_by_name(purpose_name) || purpose_by_name('Stock Plate')
    purpose.plates.create!(attrs)
  end

  def self.get_study_by_name(name)
    get_study_searcher_by_name.first(name: name)
  rescue Sequencescape::Api::ResourceNotFound => exception
    return nil
  end

  def self.get_study_searcher_by_name
    @@study_searcher ||= client.search.all.select{|s| s.name == Rails.configuration.searcher_study_by_name}.first
  end

  def self.get_searcher_by_barcode
    @@searcher ||= client.search.all.select{|s| s.name == Rails.configuration.searcher_name_by_barcode}.first
  end

  def self.get_remote_asset(barcode)
    barcodes = [barcode].flatten
    return find_first(barcode: barcodes) if barcodes.length==1
    results = find_by(barcode: barcodes)
    barcodes.each_with_index.map do |barcode|
      results.detect{|r| r.labware_barcode.human_barcode == barcode}
    end
  end

  def self.find_by_uuid(uuid, opts=nil)
    uuids = [uuid].flatten
    return find_first(uuid: uuids) if uuids.length==1
    results = find_by(uuid: uuids)
    uuids.each_with_index.map do |uuid|
      results.detect{|r| r.uuid == uuid}
    end
  end

  def self.find_by(search_conditions)
    RESOURCES.map do |klass|
      begin
        search = klass.where(search_conditions)
        search
      rescue JsonApiClient::Errors::ClientError => e
        # Ignore filter error
      end
    end.flatten
  end


  def self.find_first(search_conditions)
    RESOURCES.each do |klass|
      begin
        search = klass.where(search_conditions)
        search = search.first if search.length == 1
        return search if search
      rescue JsonApiClient::Errors::ClientError => e
        # Ignore filter error
      end
    end
    nil
  end



end

