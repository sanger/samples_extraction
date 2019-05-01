module Uuidable
  extend ActiveSupport::Concern
  included do
    before_save :generate_uuid
  end


  def generate_uuid
    update_attributes(:uuid => SecureRandom.uuid) if uuid.nil?
  end

end
