require 'sequencescape_client'

class Asset < ActiveRecord::Base
  has_many :facts
  has_and_belongs_to_many :asset_groups
  has_many :steps, :through => :asset_groups

  before_save :generate_uuid
  before_save :generate_barcode

  has_many :operations

#:class_name => 'Action', :foreign_key => 'subject_condition_group_id'
  #has_many :activities_started, -> {joins(:steps)}, :class_name => 'Activity'
  has_many :activities_started, :through => :steps, :source => :activity, :class_name => 'Activity'
  has_many :activities, :through => :asset_groups

  scope :with_fact, ->(predicate, object) {
    joins(:facts).where(:facts => {:predicate => predicate, :object => object})
  }


  scope :with_field, ->(predicate, object) {
    where(predicate => object)
  }

  scope :for_activity_type, ->(activity_type) {
    joins(:activities_started).joins(:facts).where(:activities => { :activity_type_id => activity_type.id}).order("activities.id")
  }

  scope :not_started, ->() {
    with_fact('is','NotStarted')
  }

  scope :started, ->() {
    with_fact('is','Started')
  }

  scope :compatible_with_activity_type, ->(activity_type) {
    joins(:facts).
    joins("right outer join conditions on conditions.predicate=facts.predicate and conditions.object=facts.object").
    joins("inner join condition_groups on condition_groups.id=condition_group_id").
    joins("inner join step_types on step_types.id=condition_groups.step_type_id").
    joins("inner join activity_type_step_types on activity_type_step_types.step_type_id=step_types.id").
    where("activity_type_step_types.activity_type_id = ?", activity_type)
  }

  def add_facts(list)
    list.each do |fact|
      facts << fact unless has_fact?(fact)
    end
  end

  def relation_id
    uuid
  end

  def has_fact?(fact)
    facts.any?{|f| (fact.predicate == f.predicate) && (fact.object == f.object)}
  end

  def self.assets_for_queries(queries)
    queries.map do |query|
      if Asset.first.has_attribute?(query.predicate)
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

  def facts_for_reasoning
    [facts, Fact.as_object(asset)].flatten
  end

  def reasoning!(&block)
    num_iterations = 0
    current_facts = facts_for_reasoning
    assets = current_facts.pluck(:asset)
    done = false
    while !done do

      previous_facts = current_facts.clone

      yield assets

      current_facts = facts_for_reasoning

      if ((current_facts == previous_facts) || (num_iterations >10))
        done = true
      end
      num_iterations += 1
    end
    raise 'Too many iterations while reasoning...' if num_iterations > 10
  end

  def generate_uuid
    update_attributes(:uuid => SecureRandom.uuid) if uuid.nil?
  end

  def generate_barcode
    update_attributes(:barcode => Asset.count+1) if barcode.nil?
  end

  def attrs_for_sequencescape
    return {}
    facts.reduce({}) do |memo, fact|
      memo[fact.predicate] = fact.object
      memo
    end
  end

  def update_sequencescape
    instance=SequencescapeClient.find_by_uuid(uuid)
    if instance
      instance = SequencescapeClient.update(instance, attrs_for_sequencescape)
    else
      class_name = facts.with_predicate('purpose').first.object
      instance = SequencescapeClient.create(class_name, attrs_for_sequencescape)
    end
    update_attributes(:uuid => instance.uuid, :barcode => instance.barcode.ean13)
  end
end
