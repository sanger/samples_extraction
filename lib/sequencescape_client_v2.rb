require "faraday"

module SequencescapeClientV2
  class SequencescapeClientV2::Model < JsonApiClient::Resource
    # set the api base url in an abstract base class
    self.site = "#{Rails.configuration.ss_api_v2_uri}/api/v2/"
  end

  class SequencescapeClientV2::Asset < SequencescapeClientV2::Model
  end

  class SequencescapeClientV2::Labware < SequencescapeClientV2::Model
    # The plural of labware is labware
    def self.table_name
      'labware'
    end
  end

  class SequencescapeClientV2::Plate < SequencescapeClientV2::Model
    has_many :wells
    has_many :studies, through: :well
    has_many :samples, through: :well
    has_one :purpose
  end

  class SequencescapeClientV2::TubeRack < SequencescapeClientV2::Model
    has_many :racked_tubes
    has_one :purpose
  end

  class SequencescapeClientV2::Purpose < SequencescapeClientV2::Model
  end

  class SequencescapeClientV2::Well < SequencescapeClientV2::Model
    has_many :aliquots
    has_many :studies, through: :aliquot
    has_many :samples, through: :aliquot
  end

  class SequencescapeClientV2::Tube < SequencescapeClientV2::Model
    has_many :aliquots
    has_many :studies, through: :aliquot
    has_many :samples, through: :aliquot
  end

  class SequencescapeClientV2::RackedTube < SequencescapeClientV2::Model
    has_one :tube
    has_one :tube_rack
  end

  class SequencescapeClientV2::Aliquot < SequencescapeClientV2::Model
    belongs_to :asset
    has_one :study
    has_one :sample
  end

  class SequencescapeClientV2::Study < SequencescapeClientV2::Model
    has_many :samples
  end

  class SequencescapeClientV2::Sample < SequencescapeClientV2::Model
    has_many :studies
    has_one :sample_metadata
  end

  class SequencescapeClientV2::SampleMetadatum < SequencescapeClientV2::Model
    belongs_to :sample
  end
end
