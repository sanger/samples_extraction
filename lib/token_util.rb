module TokenUtil
  def self.UUID_REGEXP
    /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  end

  def self.WILDCARD_REGEXP
    /\?\w*/
  end

  def self.LOCATION_REGEXP
    /^([A-H])(\d{1,2})$/
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

  def self.generate_positions(letters, columns)
    size=letters.size * columns.size
    location_for_position = size.times.map do |i|
      "#{letters[(i/columns.length).floor]}#{pad((columns[i%columns.length]).to_s,'0',2)}"
    end
  end

  def self.pad(str,chr,size)
    "#{(size-str.size).times.map{chr}.join('')}#{str}"
  end

  def self.pad_location(location)
    parts = location.match(TokenUtil.LOCATION_REGEXP)
    return nil if parts.length == 0
    letter = parts[1]
    number = parts[2]
    number = TokenUtil.pad(number,"0",2) unless number.length == 2
    "#{letter}#{number}"
  end

end
