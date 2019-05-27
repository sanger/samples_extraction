module TokenUtil
  def self.UUID_REGEXP
    /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  end

  def self.WILDCARD_REGEXP
    /\?\w*/
  end

  def self.is_uuid?(str)
    str.kind_of?(String) && !str.match(TokenUtil.UUID_REGEXP).nil?
  end

  def self.uuid(str)
    str.match(TokenUtil.UUID_REGEXP)[0]
  end

  def self.is_wildcard?(str)
    str.kind_of?(String) && !str.match(TokenUtil.WILDCARD_REGEXP).nil?
  end

  def self.to_asset_group_name(wildcard)
    return wildcard if wildcard.nil?
    wildcard.gsub('?', '')
  end
end
