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

  scope :for_assets, ->(assets) { joins(:asset_group => :assets).where(:asset_group => {
    :asset_groups_assets=> {:asset_id => assets }
    })
  }

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

  def step(step_type, user, step_params)
    step = steps.in_progress.first
    if step.nil? && step_params.nil?
      return steps.create!(:step_type => step_type, :asset_group_id => asset_group.id, :user_id => user.id)
    end
    if step_params
      #step = Step.find_by(:step_type => step_type, :activity => self, :in_progress? => true)
      unless step
        group = AssetGroup.create!
        step = steps.create!(:step_type => step_type, :asset_group_id => group.id, :user_id => user.id, :in_progress? => true)
      end
      step_params.each do |params|
        step.progress_with(params)
      end
    else
      step.finish
    end
  end

end
