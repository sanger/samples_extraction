#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'rest-client'
require 'pry'
require 'json'
module SequencescapeClient
  HEADERS = {
    'X-Sequencescape-Client-ID' => 'development',
    'Sequencescape-Client-ID'=> 'development',
    'Accept' => 'application/json',
    'Content-Type' => 'application/json'
  }

  SequencescapeClientException = Class.new(StandardError)

  class SequencescapeClient

    #attr_reader :root_path

    def base_url
      #configatron.fetch(:sequencescape_client_api)
      "http://localhost:3000/api/1"
    end

    def root_path(instance)
      get(instance, nil)
    end

    def path_to(instance, target)
      raise SequencescapeClientException, "SequencescapeClient service URL not set" if base_url.nil?
      [base_url, instance.endpoint, target].compact.join('/')
    end

    def parse_json(str)
      return nil if str=='null'
      JSON.parse(str)
    rescue JSON::ParserError => e
      raise SequencescapeClientException.new(e), "SequencescapeClient is returning unexpected content", e.backtrace
    end

    def get(instance, target, method=nil)
      url = root_path(instance)["actions"][method] if method
      url ||= path_to(instance,target)
      parse_json(RestClient.get(url, HEADERS))
    rescue Errno::ECONNREFUSED => e
      raise SequencescapeClientException.new(e), "SequencescapeClient service is down", e.backtrace
    end

    def post(instance, target, payload, method=nil)
      url = root_path(instance)["actions"][method] if method
      url ||= path_to(instance,target)
      parse_json(RestClient.post(url, payload, HEADERS))
    rescue Errno::ECONNREFUSED => e
      raise SequencescapeClientException.new(e), "SequencescapeClient service is down", e.backtrace
    rescue RestClient::UnprocessableEntity => e
      return parse_json(e.response)
    end

    def put(instance, target, payload, method=nil)
      url = root_path(instance)["actions"][method] if method
      url ||= path_to(instance,target)
      parse_json(RestClient.put(url, payload, HEADERS))
    rescue Errno::ECONNREFUSED => e
      raise SequencescapeClientException.new(e), "SequencescapeClient service is down", e.backtrace
    end

  end

  class Endpoint

    def self.endpoint_name(name)
      @endpoint = name
    end

    class << self
      attr_reader :endpoint
    end

    def initialize(params)
    end

  end

  module EndpointReadActions
    module ClassMethods
      def read
        attrs = SequencescapeClient.new.get(self, nil,  nil)
        new(attrs) unless attrs.nil?
      end
    end
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
  end


  module EndpointCreateActions
    module ClassMethods
      def creation_params(params)
        params
      end

      def create(params)
        attrs = SequencescapeClient.new.post(self, nil, creation_params(params), "create")
        new(attrs) unless attrs.nil?
      end
    end
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
  end

  module EndpointUpdateActions
    module ClassMethods
      def update(target, params)
        attrs = SequencescapeClient.new.put(self, target, params, "update", "update")
        new(attrs) unless attrs.nil?
      end
    end
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
  end

  class PlatePurposes < Endpoint
    endpoint_name 'plate_purposes'
    include EndpointReadActions
    attr_reader :purposes

    def initialize(params)
      @purposes = params
    end

    def plate_creator_for(purpose_name)
      purpose_uuid = @purposes["plate_purposes"].select{|p| p["name"]===purpose_name}.first["uuid"]
      Class.new(Plate) do
        endpoint_name(purpose_uuid+"/plates")
      end
    end
  end

  class Plate < Endpoint
    attr_reader :plate
    include EndpointCreateActions

    include EndpointReadActions

    def initialize(plate_params)
      @plate = plate_params
    end

    def instance
      @plate["plate"]
    end
  end


  #include Sequencescape::Api::Rails::ApplicationController

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
    #return api.plate.find(uuid)

    k=Class.new(Plate) do
      endpoint_name(uuid)
    end
    k.read.instance
  rescue RestClient::NotFound
    return nil
  end

  def self.update(instance, attrs)
  end

  def self.create(purpose_name, attrs)
    api.plate_creation.create!({
       :user => 'b55f7a90-54c6-11e6-9ffd-44fb42fffe72',
       :parent => nil,
       :child_purpose => '8a4da160-54c6-11e6-b689-44fb42fffe72'
     })
    #plate_creator = PlatePurposes.read.plate_creator_for(purpose_name)
    #plate_creator.create(attrs).instance
  end
end

#plate = SequencescapeClient.create("Stock Plate", {})
#plate = SequencescapeClient.find_by_uuid(plate["uuid"])
plate = SequencescapeClient.find_by_uuid("111")

#SequencescapeClient::PlateCreation.create(
#  {
#     :plate_creation =>{
#       :user => 'b55f7a90-54c6-11e6-9ffd-44fb42fffe72',
#       :parent => nil,
#       :child_purpose => '8a4da160-54c6-11e6-b689-44fb42fffe72'
#     }
#   }.to_json
# )
