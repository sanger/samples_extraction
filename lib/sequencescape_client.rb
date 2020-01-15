#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'pry'
require 'sequencescape-api'
require 'sequencescape'

require 'sequencescape_client_v2'

class SequencescapeClient

  def self.RESOURCES_FOR_UUID_SEARCH
    [
      SequencescapeClientV2::Plate,
      SequencescapeClientV2::Tube,
      SequencescapeClientV2::Well
    ]
  end

  def self.RESOURCES_FOR_BARCODE_SEARCH
    [
      SequencescapeClientV2::Plate,
      SequencescapeClientV2::Tube
    ]
  end

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

  def self.version_1_find_by_uuid(uuid, type=:plate, errors=[])
    catch_error_messages(errors) do
      client.send(type).find(uuid)
    end
  end

  def self.update_extraction_attributes(instance, attrs, username='test', errors=[])
    catch_error_messages(errors) do
      instance.extraction_attributes.create!(:attributes_update => attrs, :created_by => username)
    end
  end

  def self.purpose_by_name(name, errors=[])
    catch_error_messages(errors) do
      client.plate_purpose.all.select{|p| p.name===name}.first
    end
  end

  def self.create_plate(purpose_name, attrs, errors=[])
    catch_error_messages(errors) do
      attrs = {}
      purpose = purpose_by_name(purpose_name) || purpose_by_name('Stock Plate')
      purpose.plates.create!(attrs)
    end
  end

  def self.get_remote_asset(barcode, errors = [])
    barcodes = [barcode].flatten
    return find_first(self.RESOURCES_FOR_BARCODE_SEARCH, { barcode: barcodes }, errors) if barcodes.length==1
    results = find_by(self.RESOURCES_FOR_BARCODE_SEARCH, { barcode: barcodes }, errors)
    barcodes.each_with_index.map do |barcode|
      results.detect{|r| r.labware_barcode['human_barcode'] == barcode}
    end
  end

  def self.find_by_uuid(uuid, errors=[])
    uuids = [uuid].flatten
    return find_first(self.RESOURCES_FOR_UUID_SEARCH, { uuid: uuids }, errors) if uuids.length==1
    results = find_by(self.RESOURCES_FOR_UUID_SEARCH, { uuid: uuids }, errors)
    uuids.each_with_index.map do |uuid|
      results.detect{|r| r.uuid == uuid}
    end
  end

  def self.catch_error_messages(errors=[], &block)
    begin
      yield block
    rescue JsonApiClient::Errors::ClientError => e
      # Ignore filter error
      nil
    rescue JsonApiClient::Errors::ConnectionError => e
      errors.push(e.message)
      nil
    rescue StandardError => e
      errors.push(e.message)
      nil
    end
  end

  def self.find_by(resources, search_conditions, errors = [])
    value = resources.map do |klass|
      catch_error_messages(errors) do
        klass.where(search_conditions)
      end
    end
    value.flatten.compact
  end

  def self.find_first(resources, search_conditions, errors = [])
    resources.each do |klass|
      catch_error_messages(errors) do
        search = klass.where(search_conditions)
        search = search.first if search && search.length == 1
        return search if search
      end
    end
    nil
  end



end

