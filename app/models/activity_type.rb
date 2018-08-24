class ActivityType < ActiveRecord::Base
  has_many :activities
  has_many :kit_types
  has_many :activity_type_step_types
  has_many :step_types, :through => :activity_type_step_types
  has_many :condition_groups, :through => :step_types
  
  after_update :touch_activities

  has_and_belongs_to_many :instruments

  has_many :conditions, :through => :condition_groups

  has_many :activity_type_compatibilities
  has_many :assets, -> { distinct }, :through => :activity_type_compatibilities

  include Deprecatable

  def touch_activities
    activities.each(&:touch)
  end

  before_update :parse_n3

  attr_accessor :n3_definition

  def available?
    superceded_by.nil?
  end

  def parse_n3
    return
    unless n3_definition.nil?
      SupportN3::parse_string(n3_definition, {})
    end
  end

  def after_deprecate
    superceded_by.update_attributes(
      activities: superceded_by.activities | activities,
      kit_types:  superceded_by.kit_types | kit_types, 
      instruments: superceded_by.instruments | instruments
      )
    superceded_by.save!
  end


  def compatible_with?(assets)
    condition_groups.any?{|c| c.compatible_with?(assets)}
  end

  def to_n3
    render :n3
  end
end
