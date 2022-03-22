# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
require 'sequencescape-api'
require 'sequencescape'

require 'sequencescape_client_v2'

class SequencescapeClient
  @purposes = nil

  def self.api_connection_options
    {
      :namespace => 'SamplesExtraction',
      :url => Rails.configuration.ss_uri,
      :authorisation => Rails.configuration.ss_authorisation,
      :read_timeout => 60
    }
  end

  def self.client
    @client ||= Sequencescape::Api.new(self.api_connection_options)
  end

  def self.version_1_find_by_uuid(uuid, type = :plate)
    client.send(type).find(uuid)
  rescue Sequencescape::Api::ResourceNotFound => exception
    return nil
  end

  # below creates a record in the 'extraction_attributes' table in Sequencescape
  # this, in turn, triggers creation of aliquots against the plate
  def self.update_extraction_attributes(instance, attrs, username = 'test')
    instance.extraction_attributes.create!(:attributes_update => attrs, :created_by => username)
  end

  def self.purpose_by_name(name)
    client.plate_purpose.all.select { |p| p.name === name }.first
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
    @@study_searcher ||= client.search.all.select { |s| s.name == Rails.configuration.searcher_study_by_name }.first
  end

  def self.get_searcher_by_barcode
    @@searcher ||= client.search.all.select { |s| s.name == Rails.configuration.searcher_name_by_barcode }.first
  end

  def self.get_remote_asset(barcode)
    find_by(barcode: barcode)
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end

  # TODO: In most cases we should know what type of record we're looking up.
  def self.find_by(search_conditions)
    [
      SequencescapeClientV2::Plate.includes('wells.aliquots.sample'),
      SequencescapeClientV2::Tube.includes('aliquots.sample'),
      SequencescapeClientV2::Well.includes('aliquots.sample'),
      SequencescapeClientV2::TubeRack.includes('racked_tubes.tube.aliquots.sample')
    ].each do |klass|
      begin
        search = klass.where(search_conditions).first
        return search if search
      rescue JsonApiClient::Errors::ClientError => e
        # Ignore filter error
      end
    end
    nil
  end
end
