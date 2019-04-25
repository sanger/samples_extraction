module TokenUtil
  def self.UUID_REGEXP
    /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  end

  def self.is_uuid?(str)
    str.kind_of?(String) && str.match(TokenUtil.UUID_REGEXP)
  end

  def self.uuid(str)
    str.match(TokenUtil.UUID_REGEXP)[0]
  end
end
