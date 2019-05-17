module Uuidable
  extend ActiveSupport::Concern
  included do
    before_save :uuid

    alias_method :generate_uuid!, :uuid
  end

  def uuid
    self[:uuid] ||= SecureRandom.uuid
  end

end
