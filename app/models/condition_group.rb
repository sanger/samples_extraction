class ConditionGroup < ActiveRecord::Base
  belongs_to :step_type
  has_many :conditions

  def compatible_with?(assets)
    return false if cardinality && (assets.length != cardinality)
    conditions.all?{|condition| condition.compatible_with?(assets)}
  end

  def conditions_compatible_with?(assets)
    [assets].flatten.all? do |asset|
      conditions.all? do |condition|
        condition.compatible_with?(asset)
      end
    end
  end
end
