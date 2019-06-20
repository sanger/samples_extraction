require 'sequencescape_client'
require 'date'

require 'pry'

class Asset < ActiveRecord::Base
  include Uuidable
  include Printables::Instance
  include Asset::Import
  include Asset::Export
  include Assets::WebsocketEvents
  include Assets::FactsManagement

  has_one :uploaded_file

  alias_attribute :name, :uuid

  has_many :facts, :dependent => :delete_all
  has_many :asset_groups_assets, dependent: :destroy
  has_many :asset_groups, through: :asset_groups_assets
  has_many :steps, :through => :asset_groups



  def update_compatible_activity_type
    ActivityType.visible.all.each do |at|
      activity_types << at if at.compatible_with?(self)
    end
  end

  has_many :operations, dependent: :nullify

  has_many :activity_type_compatibilities
  has_many :activity_types, :through => :activity_type_compatibilities

  has_many :activities, -> { distinct }, :through => :steps

  scope :currently_changing, ->() {
    joins(:asset_groups, :steps).where(:steps => {:state => 'running'})
  }

  scope :for_activity_type, ->(activity_type) {
    joins(:activities).where(:activities => { :activity_type_id => activity_type.id})
  }

  scope :not_started, ->() {
    with_fact('is','NotStarted')
  }

  scope :started, ->() {
    with_fact('is','Started')
  }

  scope :for_printing, ->() {
    where.not(barcode: nil)
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

  scope :assets_for_queries, ->(queries) {
    queries.each_with_index.reduce(Asset) do |memo, list|
      query = list[0]
      index = list[1]
      if query.predicate=='barcode'
        memo.where(barcode: query.object)
      else
        asset = Asset.where(barcode: query.object).first
        if asset
          memo.joins(
            "INNER JOIN facts AS facts#{index} ON facts#{index}.asset_id=assets.id"
            ).where("facts#{index}.predicate" => query.predicate,
            "facts#{index}.object_asset_id" => asset.id)
        else
          memo.joins(
            "INNER JOIN facts AS facts#{index} ON facts#{index}.asset_id=assets.id"
            ).where("facts#{index}.predicate" => query.predicate,
            "facts#{index}.object" => query.object)
        end
      end
    end
  }

  def short_description
    "#{aliquot_type} #{class_type} #{barcode.blank? ? '#' : barcode}".chomp
  end

  def aliquot_type
    f = facts.with_predicate('aliquotType').first
    f ? f.object : ""
  end

  def relation_id
    uuid
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

  def build_barcode(index)
    self.barcode = SBCF::SangerBarcode.new({
      prefix: Rails.application.config.barcode_prefix,
      number: index
    }).human_barcode
  end

  def generate_barcode
    save
    if barcode.nil?
      update_attributes({
        barcode: SBCF::SangerBarcode.new({
          prefix: Rails.application.config.barcode_prefix,
          number: self.id
          }).human_barcode
        }
      )
    end
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

  def study_and_barcode
    [study_name, barcode_sequencescaped].join(' ')
  end

  def barcode_sequencescaped
    unless barcode.match(/^\d+$/)
      return barcode.match(/\d+/)[0] if barcode.match(/\d+/)
      return ""
    end
    ean13 = barcode.rjust(13, '0')
    ean13.slice!(0,3)
    ean13.slice!(ean13.length-3,3)
    ean13.to_i
  end

  def study_name
    if has_predicate?('study_name')
      return facts.with_predicate('study_name').first.object
    end
    return ''
  end

  def printable_object(username = 'unknown')
    return nil if barcode.nil?
    if ((class_type=='Plate')||(class_type=='TubeRack'))
      return {
        :label => {
          :barcode => barcode,
          :top_left => DateTime.now.strftime('%d/%b/%y'),
          :top_right => info_line, #username,
          :bottom_right => study_and_barcode,
          :bottom_left => barcode
        }
      }
    end
    return {:label => {
      :barcode => barcode,
      :barcode2d => barcode,
      :top_line => barcode,
      :bottom_line => info_line
      }
    }
  end

  def position_value
    val = facts.map(&:position).compact.first
    return "" if val.nil?
    "_#{(val.to_i+1).to_s}"
  end

  def info_line
    ["#{class_name}", "#{aliquot}","#{position_value}"].join(' ').strip
  end

  def class_name
    purposes_facts = facts.with_predicate('purpose')
    if purposes_facts.count > 0
      return purposes_facts.first.object
    end
    return ''
  end

  def aliquot
    purposes_facts = facts.with_predicate('aliquotType')
    if purposes_facts.count > 0
      return purposes_facts.first.object
    end
    return ''
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

  def barcode_type
    btypes = facts.with_predicate('barcodeType')
    return 'ean13' if btypes.empty?
    btypes.first.object.downcase
  end

  def validate_rack_content
    errors=[]
    errors.push(more_than_one_aliquot_type_validation)
    errors
  end

  def is_sequencescape_plate?
    has_literal?('barcodeType', 'SequencescapePlate')
  end

  def to_n3
    render :n3
  end
end
