module TokenUtil
  def self.UUID_REGEXP
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
  end

  def self.fluidx_barcode_prefix
    'F'
  end

  def self.MACHINE_BARCODE
    /^\d*$/
  end

  def self.HUMAN_BARCODE
    /^\w*$/
  end

  def self.invalid_barcode?(barcode)
    barcode.nil? || (barcode.kind_of?(String) && barcode.to_s.empty?)
  end

  def self.machine_barcode?(barcode)
    return false if invalid_barcode?(barcode)
    barcode.to_s.match?(TokenUtil.MACHINE_BARCODE)
  end

  def self.human_barcode?(barcode)
    return false if invalid_barcode?(barcode)
    # If we change the next line, we should change it to check the regexp
    !machine_barcode?(barcode)
  end

  def self.machine_barcode(barcode)
    return SBCF::SangerBarcode.from_human(barcode).machine_barcode.to_s if human_barcode?(barcode)
    barcode.to_s
  end

  def self.human_barcode(barcode)
    return SBCF::SangerBarcode.from_machine(barcode).human_barcode.to_s if machine_barcode?(barcode)
    barcode.to_s
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

  def self.quote_if_uuid(str)
    return quote(str) if is_uuid?(str)
    return str
  end

  def self.is_valid_fluidx_barcode?(barcode)
    barcode.to_s.starts_with?(fluidx_barcode_prefix)
  end

  def self.uuid(str)
    str.match(TokenUtil.UUID_REGEXP)[0]
  end

  def self.is_wildcard?(str)
    str.kind_of?(String) && !str.match(TokenUtil.WILDCARD_REGEXP).nil?
  end

  def self.kind_of_asset_id?(str)
    !!(str.kind_of?(String) && (is_wildcard?(str) || is_uuid?(str)))
  end

  def self.to_asset_group_name(wildcard)
    return wildcard if wildcard.nil?
    wildcard.gsub('?', '')
  end

  def self.generate_positions(letters, columns)
    size=letters.size * columns.size
    location_for_position = size.times.map do |i|
      "#{letters[(i%letters.length).floor]}#{pad((columns[(i/letters.length).floor]).to_s,'0',2)}"
    end
  end

  def self.pad(str,chr,size)
    "#{(size-str.size).times.map{chr}.join('')}#{str}"
  end

  def self.unpad_location(location)
    return location unless location
    loc = location.match(/(\w)(0*)(\d*)/)
    loc[1]+loc[3]
  end

  def self.pad_location(location)
    return location unless location
    parts = location.match(TokenUtil.LOCATION_REGEXP)
    return nil if parts.length == 0
    letter = parts[1]
    number = parts[2]
    number = TokenUtil.pad(number,"0",2) unless number.length == 2
    "#{letter}#{number}"
  end

  def self.quote(str)
    return str unless str
    "\"#{str}\""
  end

  def self.unquote(str)
    return str unless str
    str.gsub(/\"/,"")
  end

end
