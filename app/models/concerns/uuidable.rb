module Uuidable
  extend ActiveSupport::Concern
  included { attribute :uuid, default: -> { SecureRandom.uuid } }
end
