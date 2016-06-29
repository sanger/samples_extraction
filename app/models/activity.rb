class Activity < ActiveRecord::Base
  validates :activity_type, :presence => true
  belongs_to :activity_type
  has_many :steps

  has_many :step_types, :through => :activity_type

  def assets
    steps.last.assets
  end

  def steps_for(assets)
    assets.map(&:steps).flatten.compact
  end

  def step_types_for(assets)
    step_types.select{|step_type| step_type.compatible_with?(assets)}
  end

end
