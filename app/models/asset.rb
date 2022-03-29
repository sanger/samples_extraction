require 'sequencescape_client'
require 'date'

class Asset < ApplicationRecord
  DataIntegrityError = Class.new(StandardError)

  include Uuidable
  include Printables::Instance
  include Assets::Import
  include Assets::Export
  include Assets::FactsManagement
  include Assets::TractionFields

  has_one :uploaded_file

  alias_attribute :name, :uuid

  has_many :facts, dependent: :delete_all do
    # If we've already loaded our facts, avoid hitting the database a
    # second time.
    def with_predicate(predicate)
      if loaded?
        select { |fact| fact.predicate.casecmp?(predicate) }
      else
        super
      end
    end
  end

  has_many :asset_groups_assets, dependent: :destroy
  has_many :asset_groups, through: :asset_groups_assets
  has_many :steps, through: :asset_groups
  has_many :activities_affected, -> { distinct }, through: :asset_groups, class_name: 'Activity', source: :activity_owner

  def update_compatible_activity_type
    ActivityType.not_deprecated.all.each do |at|
      activity_types << at if at.compatible_with?(self)
    end
  end

  has_many :operations, dependent: :nullify

  has_many :activity_type_compatibilities
  has_many :activity_types, :through => :activity_type_compatibilities

  has_many :activities, -> { distinct }, :through => :steps

  scope :currently_changing, ->() {
    joins(:asset_groups, :steps).where(:steps => { :state => 'running' })
  }

  scope :for_activity_type, ->(activity_type) {
    joins(:activities).where(:activities => { :activity_type_id => activity_type.id })
  }

  scope :not_started, ->() {
    with_fact('is', 'NotStarted')
  }

  scope :started, ->() {
    with_fact('is', 'Started')
  }

  scope :for_printing, ->() {
    where.not(barcode: nil)
  }

  scope :assets_for_queries, ->(queries) {
    queries.each_with_index.reduce(Asset) do |memo, list|
      query = list[0]
      index = list[1]
      if query.predicate == 'barcode'
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

  # Returns all facts with the predicate 'sample_uuid'
  # associated with the asset. This can either be those associated
  # directly with the asset (such as for tubes) or
  # via contained assets (for a plate)
  def sample_uuid_facts
    if has_predicate?('sample_uuid')
      facts.with_predicate('sample_uuid')
    else
      facts.with_predicate('contains').flat_map do |fact|
        fact.object_asset.sample_uuid_facts
      end
    end
  end

  # Walk back down the transfers, until you find the oldest.
  # The created_before filter prevents us from an infinite
  # loop in the event asset_a > asset_b > asset_a
  def walk_transfers(before = nil)
    transfers = facts.with_predicate('transferredFrom')
    parent_fact = if transfers.respond_to?(:created_before)
                    transfers.created_before(before).last
                  else
                    transfers.reverse.detect { |t| before.nil? || (t.created_at < before) }
                  end
    if parent_fact&.object_asset
      parent_fact.object_asset.walk_transfers(parent_fact.created_at)
    else
      self
    end
  end

  def relation_id
    uuid
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
                        })
    end
  end

  def study_and_barcode
    "#{study_name} #{barcode_sequencescaped}"
  end

  def barcode_sequencescaped
    unless barcode.match(/^\d+$/)
      return barcode.match(/\d+/)[0] if barcode.match(/\d+/)

      return ""
    end
    ean13 = barcode.rjust(13, '0')
    ean13.slice!(0, 3)
    ean13.slice!(ean13.length - 3, 3)
    ean13.to_i
  end

  def study_name
    if has_predicate?('study_name')
      return facts.with_predicate('study_name').first.object
    else
      if (kind_of_plate?)
        tubes = facts.with_predicate('contains').map(&:object_asset)
        if tubes.length > 0
          if tubes.first.facts.with_predicate('study_name').length > 0
            return tubes.first.facts.with_predicate('study_name').first.object
          end
        end
      end
    end

    return ''
  end

  def print_machine_barcode?
    facts.where(predicate: 'barcodeFormat', object: 'machine_barcode').count > 0
  end

  def barcode_formatted_for_printing
    if print_machine_barcode?
      mbarcode = TokenUtil.machine_barcode(barcode)
      return mbarcode if mbarcode
    end
    barcode
  end

  def printable_object(username = 'unknown')
    return nil if barcode.nil?

    if (kind_of_plate?)
      return {
        :label => {
          :barcode => barcode,
          :top_left => DateTime.now.strftime('%d/%b/%y'),
          :top_right => info_line, # username,
          :bottom_right => study_and_barcode,
          :bottom_left => barcode
        }
      }
    end
    return { :label => {
      :barcode => barcode_formatted_for_printing,
      :barcode2d => barcode_formatted_for_printing,
      :top_line => TokenUtil.human_barcode(barcode),
      :middle_line => kit_type,
      :bottom_line => info_line
    } }
  end

  def kit_type
    activities_affected&.last&.kit&.kit_type&.abbreviation
  end

  def position_value
    val = facts.filter_map(&:position).first
    return "" if val.nil?

    "_#{(val.to_i + 1).to_s}"
  end

  def info_line
    "#{purpose_name} #{aliquot} #{position_value}".strip
  end

  def purpose_name
    # @todo: Falling back to an empty string, rather than nil feels a bit risky, but this maintains earlier behaviour.
    # (We don't have any cases of facts with predicate purpose and value NULL)
    facts.with_predicate('purpose').first&.object || ''
  end

  def aliquot
    # @todo: Falling back to an empty string, rather than nil feels a bit risky, but this maintains earlier behaviour.
    # (We don't have any cases of facts with predicate aliquotType and value NULL)
    facts.with_predicate('aliquotType').first&.object || ''
  end

  def self.class_type(facts)
    class_types = facts.select { |f| f[:predicate] == 'a' }.map(&:object)
    return 'TubeRack' if class_types.include?('TubeRack')
    return 'Plate' if class_types.include?('Plate')
    return 'Tube' if class_types.include?('Tube')
    return 'SampleTube' if class_types.include?('SampleTube')
    return facts.select { |f| f[:predicate] == 'a' }.first.object if facts.select { |f| f[:predicate] == 'a' }.first

    return ""
  end

  def kind_of_plate?
    (class_type == 'Plate') || (class_type == 'TubeRack')
  end

  def has_wells?
    (kind_of_plate? && (facts.with_predicate('contains').count > 0))
  end

  def class_type
    Asset.class_type(facts)
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
    errors = []
    errors.push(more_than_one_aliquot_type_validation)
    errors
  end

  def to_n3
    render :n3
  end
end
