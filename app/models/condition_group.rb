class ConditionGroup < ActiveRecord::Base
  belongs_to :step_type
  has_many :activity_types, :through => :step_type
  has_many :conditions

  has_many :subject_actions, :class_name => 'Action', :foreign_key => 'subject_condition_group_id'
  has_many :object_actions, :class_name => 'Action', :foreign_key => 'object_condition_group_id'


  def compatible_with?(assets, related_assets = [], checked_condition_groups=[])
    if cardinality
      return false if assets.kind_of?(Array) && (assets.length > cardinality)
    end
    #return false if cardinality && (assets.length != cardinality)
    conditions.all?{|condition| condition.compatible_with?(assets, related_assets, checked_condition_groups)}
  end

  def conditions_compatible_with?(assets, related_assets = [])
    [assets].flatten.all? do |asset|
      conditions.all? do |condition|
        condition.compatible_with?(asset, related_assets)
      end
    end
  end
end
