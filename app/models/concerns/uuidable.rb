module Uuidable
  extend ActiveSupport::Concern
  included do
    attribute :uuid, default: -> { SecureRandom.uuid }
  end
end
