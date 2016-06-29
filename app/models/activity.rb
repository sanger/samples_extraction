class Activity < ActiveRecord::Base
  validates :activity_type, :presence => true
  belongs_to :activity_type
  belongs_to :instrument
  belongs_to :kit

  has_many :steps
  has_many :step_types, :through => :activity_type
  belongs_to :asset_group

  def assets
    steps.last.assets
  end

  def steps_for(assets)
    assets.map(&:steps).concat(steps).flatten.compact.uniq
  end

  def step_types_for(assets)
    step_types.select{|step_type| step_type.compatible_with?(assets)}
  end

  def create_step(step_type, asset_group)
    step = steps.create(:step_type => step_type, :asset_group_id => asset_group.id)
  end

end
