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
      :url           => Rails.configuration.ss_uri,
      :authorisation => 'development',
      :read_timeout  => 5
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

  def self.update_extraction_attributes(instance, attrs)
    instance.extraction_attributes.create!(:attributes_update => attrs, :created_by => 'test')
  end

  def self.purpose_by_name(name)
    client.plate_purpose.all.select{|p| p.name===name}.first
  end

  def self.create_plate(purpose_name, attrs)
    attrs = {}
    purpose = purpose_by_name(purpose_name) || purpose_by_name('Stock Plate')
    purpose.plates.create!(attrs)
  end

  def self.annotate_asset_with_remote_asset(asset, remote_asset)
    asset.facts << Fact.create(:predicate => 'a', :object => remote_asset.class.to_s.gsub(/Sequencescape::/,''))
    asset.facts << Fact.create(:predicate => 'is', :object => 'NotStarted')
  end

  def self.get_searcher_by_barcode
    @@searcher ||= client.search.all.select{|s| s.name == Rails.configuration.searcher_name_by_barcode}.first
  end

  def self.get_remote_asset(barcode)
    get_searcher_by_barcode.first(:barcode => barcode)
  end

  def self.find_by_barcode(barcode)
    asset = Asset.find_by_barcode(barcode)
    unless asset
      remote_asset = get_remote_asset(barcode)
      if remote_asset
        asset = Asset.create(:barcode => barcode)
        annotate_asset_with_remote_asset(asset, remote_asset)
      end
    end
    asset
  end
end

