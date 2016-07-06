class Asset < ActiveRecord::Base
  has_many :facts
  has_and_belongs_to_many :asset_groups
  has_many :steps, :through => :asset_groups

  before_save :generate_uuid
  before_save :generate_barcode

  has_many :operations

  def facts_to_s
    facts.map{|f| f.predicate+':'+f.object}.join(', ')
  end

  def generate_uuid
    update_attributes(:uuid => SecureRandom.uuid) if uuid.nil?
  end

  def generate_barcode
    update_attributes(:barcode => Asset.count+1) if barcode.nil?
  end
end
