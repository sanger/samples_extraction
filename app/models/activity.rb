require 'date'

class Activity < ActiveRecord::Base
  include Lab::Actions
  include Activities::Tasks
  include Activities::BackgroundTasks

  validates :activity_type, :presence => true
  validates :asset_group, :presence => true
  belongs_to :activity_type
  belongs_to :instrument
  belongs_to :kit
  has_many :owned_asset_groups, :class_name => 'AssetGroup', :foreign_key => 'activity_owner_id'
  has_many :steps
  has_many :step_types, :through => :activity_type
  has_many :uploads
  belongs_to :asset_group
  has_many :users, :through => :steps

  scope :for_assets, ->(assets) { joins(:asset_group => :assets).where(:asset_group => {
    :asset_groups_assets=> {:asset_id => assets }
    })
  }

  scope :for_activity_type, ->(activity_type) {
    where(:activity_type => activity_type)
  }

  scope :for_user, ->(user) { joins(:steps).where({:steps => {:user_id => user.id}}).distinct }


  class StepWithoutInputs < StandardError
  end

  scope :in_progress, ->() { where('completed_at is null')}
  scope :finished, ->() { where('completed_at is not null')}

  def active_step
    return nil unless steps.in_progress
    steps.in_progress.first
  end

  def last_user
    users.last
  end

  def finish
    update_attributes(:completed_at => DateTime.now)
  end

  def finished?
    !completed_at.nil?
  end

  def previous_steps
    asset_group.assets.includes(:steps).map(&:steps).concat(steps).flatten.sort{|a,b| a.id <=> b.id}.uniq
  end

  def assets
    steps.last.assets
  end

  def steps_for(assets)
    assets.includes(:steps).map(&:steps).concat(steps).flatten.compact.uniq
  end

  def step_types_for(assets, required_assets=nil)
    stypes = step_types.not_for_reasoning.includes(:condition_groups => :conditions).select do |step_type|
      step_type.compatible_with?(assets, required_assets)
    end.uniq
    stype = stypes.detect{|stype| steps.in_progress.for_step_type(stype).count > 0}
    stype.nil? ? stypes : [stype]
  end

  def step_types_active
    step_types_for(asset_group.assets)
  end

end
