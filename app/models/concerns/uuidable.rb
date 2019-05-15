module Uuidable
  extend ActiveSupport::Concern
  included do
    before_save :uuid
  end

  def uuid
    self[:uuid] ||= SecureRandom.uuid
  end

end
