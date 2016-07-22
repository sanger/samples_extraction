require 'date'

class Activity < ActiveRecord::Base
  validates :activity_type, :presence => true
  validates :instrument, :presence => true
  validates :kit, :presence => true
  validates :asset_group, :presence => true
  belongs_to :activity_type
  belongs_to :instrument
  belongs_to :kit

  has_many :steps
  has_many :step_types, :through => :activity_type

  has_many :uploads

  belongs_to :asset_group


  scope :in_progress, ->() { where('completed_at is null')}
  scope :finished, ->() { where('completed_at is not null')}

  def finish
    update_attributes(:completed_at => DateTime.now)
  end

  def finished?
    !completed_at.nil?
  end

  def previous_steps
    asset_group.assets.includes(:steps).map(&:steps).concat(steps).flatten.sort{|a,b| a.created_at <=> b.created_at}.uniq
  end

  def assets
    steps.last.assets
  end

  def steps_for(assets)
    assets.includes(:steps).map(&:steps).concat(steps).flatten.compact.uniq
  end

  def step_types_for(assets, required_assets=nil)
    step_types.includes(:condition_groups => :conditions).select{|step_type| step_type.compatible_with?(assets, required_assets)}
  end

  def create_step(step_type)
    group = AssetGroup.create
    group.assets << asset_group.assets
    step = steps.create(:step_type => step_type, :asset_group_id => group.id)
  end

end
