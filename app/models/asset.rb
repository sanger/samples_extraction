class Asset < ActiveRecord::Base
  has_many :facts
  has_and_belongs_to_many :asset_groups
  has_many :steps, :through => :asset_groups

  before_save :generate_uuid
  before_save :generate_barcode

  has_many :operations

  has_many :activities, :through => :asset_groups

  scope :with_fact, ->(predicate, object) {
    joins(:facts).where(:facts => {:predicate => predicate, :object => object})
  }

  scope :with_field, ->(predicate, object) {
    where(predicate => object)
  }

  def relation_id
    uuid
  end

  def has_fact?(fact)
    facts.any?{|f| (fact.predicate == f.predicate) && (fact.object == f.object)}
  end

  def self.assets_for_queries(queries)
    queries.map do |query|
      if Asset.has_attribute?(query.predicate)
        Asset.with_field(query.predicate, query.object)
      else
        Asset.with_fact(query.predicate, query.object)
      end
    end.reduce([]) do |memo, result|
      if memo.empty?
        result
      else
        result & memo
      end
    end
  end


  def facts_to_s
    facts.each do |fact|
      render :partial => fact
    end
  end

  def condition_groups_init
    obj = {}
    obj[barcode] = { :template => 'templates/asset_facts'}
    obj[barcode][:facts]=facts.map do |fact|
          {
            :cssClasses => '',
            :name => uuid,
            :actionType => 'createAsset',
            :predicate => fact.predicate,
            :object => fact.object
          }
        end

    obj
  end


  def generate_uuid
    update_attributes(:uuid => SecureRandom.uuid) if uuid.nil?
  end

  def generate_barcode
    update_attributes(:barcode => Asset.count+1) if barcode.nil?
  end
end
