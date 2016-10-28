require 'sequencescape_client'
require 'barcode'


require 'pry'

class Asset < ActiveRecord::Base
  include Lab::Actions
  include Printables::Instance
  extend Asset::Import
  include Asset::Export

  has_many :facts
  has_and_belongs_to_many :asset_groups
  has_many :steps, :through => :asset_groups

  before_save :generate_uuid
  #before_save :generate_barcode


  def update_compatible_activity_type
    ActivityType.visible.all.each do |at|
      activity_types << at if at.compatible_with?(self)
    end
  end

  has_many :operations

  has_many :activity_type_compatibilities
  has_many :activity_types, :through => :activity_type_compatibilities

#:class_name => 'Action', :foreign_key => 'subject_condition_group_id'
  #has_many :activities_started, -> {joins(:steps)}, :class_name => 'Activity'
  has_many :activities_started, -> { uniq }, :through => :steps, :source => :activity, :class_name => 'Activity'
  has_many :activities, :through => :asset_groups

  scope :with_fact, ->(predicate, object) {
    joins(:facts).where(:facts => {:predicate => predicate, :object => object})
  }


  scope :with_field, ->(predicate, object) {
    where(predicate => object)
  }

  scope :with_predicate, ->(predicate) {
    joins(:fact).where(:facts => {:predicate => predicate})
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

  scope :compatible2_with_activity_type, ->(activity_type) {
    joins(:facts).
    joins("right outer join conditions on conditions.predicate=facts.predicate and conditions.object=facts.object").
    joins("inner join condition_groups on condition_groups.id=condition_group_id").
    joins("inner join step_types on step_types.id=condition_groups.step_type_id").
    joins("inner join activity_type_step_types on activity_type_step_types.step_type_id=step_types.id").
    where("activity_type_step_types.activity_type_id = ?", activity_type)
  }

  scope :compatible_with_activity_type, ->(activity_type) {
    st = activity_type.step_types.select do |st|
      st.condition_groups.select{|cg| cg.conditions.any?{|c| c.predicate == 'is' && c.object == 'NotStarted'}}
    end.first
    st_checks = [st.id, st.condition_groups.map(&:id)]

    joins(:facts).
    joins("right outer join conditions on conditions.predicate=facts.predicate and conditions.object=facts.object").
    joins("inner join condition_groups on condition_groups.id=condition_group_id").
    joins("inner join step_types on step_types.id=condition_groups.step_type_id").
    joins("inner join activity_type_step_types on activity_type_step_types.step_type_id=step_types.id").
    where("activity_type_step_types.activity_type_id = ? and activity_type_step_types.step_type_id = ? and condition_groups.id in (?)", activity_type, st_checks[0], st_checks[1])
  }


  #def self.assets_compatible_with_activity_type(assets, activity_type)
  # scope :assets_compatible_with_activity_type, ->(assets, activity_type) {
  #   select do |asset|
  #     activity_type.step_types.any? do |s|
  #       s.condition_groups.all? do |cg|
  #         cg.compatible_with?(asset)
  #       end
  #     end
  #   end
  # }

  def add_facts(list, position=nil)
    ActiveRecord::Base.transaction do |t|
      list = [list].flatten
      list.each do |fact|
        unless has_fact?(fact)
          if ((fact.position.nil?) || (fact.position == position))
            facts << fact
          end
        end
      end
    end
  end

  def relation_id
    uuid
  end

  def has_literal?(predicate, object)
    facts.any?{|f| f.predicate == predicate && f.object == object}
  end

  def has_fact?(fact)
    facts.any? do |f|
      if f.object.nil?
        ((fact.predicate == f.predicate) && (fact.object_asset == f.object_asset) &&
          (fact.to_add_by == f.to_add_by) && (fact.to_remove_by == f.to_remove_by))
      else
        other_conds=true
        if fact.respond_to?(:to_add_by)
          other_conds = (fact.to_add_by == f.to_add_by) && (fact.to_remove_by == f.to_remove_by)
        end
        ((fact.predicate == f.predicate) && (fact.object == f.object) && other_conds)
      end
    end
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

  def object_value(fact)
    if fact.object
      object = fact.object
    else
      if fact.object_asset
        object = fact.object_asset.barcode
      else
        object=nil
      end
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
            :object_reference => fact.object_asset_id,
            :object_label => fact.object_label,
            :object => object_value(fact)
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

  def generate_barcode(i)
    update_attributes(:barcode => Barcode.calculate_barcode(Rails.application.config.barcode_prefix,Asset.count+i)) if barcode.nil?
  end

  def attrs_for_sequencescape(traversed_list = [])
    hash = facts.map do |fact|
      if fact.literal?
        [fact.predicate,  fact.object_value]
      else
        if traversed_list.include?(fact.object_value)
          [fact.predicate, fact.object_value.uuid]
        else
          traversed_list.push(fact.object_value)
          [fact.predicate, fact.object_value.attrs_for_sequencescape(traversed_list)]
        end
      end
    end.reduce({}) do |memo, list|
      predicate,object = list
      if memo[predicate] || memo[predicate.pluralize]
        # Updates name of list to pluralized name
        unless memo[predicate].kind_of? Array
          memo[predicate.pluralize] = [memo[predicate]]
          memo = memo.except!(predicate) if predicate != predicate.pluralize
        end
        memo[predicate.pluralize].push(object)
      else
        memo[predicate] = object
      end
      memo
    end
    #return {:uuid => uuid, :barcode => { :prefix => 'SE', :number => 14 }}
    hash
  end

  def method_missing(sym, *args, &block)
    list_facts = facts.with_predicate(sym.to_s.singularize)
    return list_facts.map(&:object_value) unless list_facts.empty?
    super(sym, *args, &block)
  end

  def respond_to?(sym, include_private = false)
    (!facts.with_predicate(sym.to_s.singularize).empty? || super(sym, include_private))
  end

  def printable_object
    return {:label => {
      :barcode => barcode,
      :top_line => Barcode.barcode_to_human(barcode) || barcode,
      :bottom_line => class_name }
    }
  end

  def class_name
    purposes_facts = facts.with_predicate('purpose')
    if purposes_facts.count > 0
      return purposes_facts.first.object
    end
    return ''
  end

  def first_value_for(predicate)
    facts.with_predicate(predicate).first.object
  end

  def position_name_for_symphony
    str = first_value_for('location')
    [str[0], str[1..-1]].join(':')
  end

  def position_index_for_symphony
    str = first_value_for('location')
    (str[1..-1] * 12) + (str[0].ord - 'A'.ord)
  end

  def asset_description
    names = facts.with_predicate('a').map(&:object).join(' ')
    types = facts.with_predicate('aliquotType').map(&:object).join(' ')
    return names + ' ' + types
  end

  def self.class_type(facts)
    class_types = facts.select{|f| f[:predicate] == 'a'}.map(&:object)
    return 'TubeRack' if class_types.include?('TubeRack')
    return 'Plate' if class_types.include?('Plate')
    return 'Tube' if class_types.include?('Tube')
    return 'SampleTube' if class_types.include?('SampleTube')
    return facts.select{|f| f[:predicate] == 'a'}.first.object if facts.select{|f| f[:predicate] == 'a'}.first
    return ""
  end

  def class_type
    Asset.class_type(facts)
  end


  def contains_location?(location)
    facts.with_predicate('contains').any? do |f|
      f.object_asset.facts.with_predicate('location').map(&:object).include?(location)
    end
  end

  def assets_at_location(location)
    facts.with_predicate('contains').map(&:object_asset).select do |a|
      a.facts.with_predicate('location').map(&:object).include?(location)
    end
  end

  def remove_from_parent(parent)
    facts.with_predicate('parent').select{|f| f.object_asset==parent}.each(&:destroy)
    facts.with_predicate('location').each(&:destroy)
  end


  def duplicated_tubes_validation
    contained_assets = facts.with_predicate('contains').map(&:object_asset)
    duplicated = contained_assets.select do |element|
      element.facts.with_predicate('location').count > 1
    end.uniq
    unless duplicated.empty?
      return duplicated.map do |duplicate_tube|
        "The tube #{duplicated_tube.barcode} is duplicated in the layout"
      end
    end
    return []
  end

  def more_than_one_aliquot_type_validation
    if facts.with_predicate('contains').map(&:object_asset).map do |well|
      well.facts.with_predicate('aliquotType').map(&:object)
      end.flatten.uniq.count > 1
      return ['More than one aliquot type in the same rack']
    end
    return []
  end


  def validate_rack_content
    errors=[]
    errors.push(more_than_one_aliquot_type_validation)
    #errors.push(duplicated_tubes_validation)
    errors
  end
end
