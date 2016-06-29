class StepType < ActiveRecord::Base
  has_many :activity_type_step_types
  has_many :activity_types, :through => :activity_type_step_types
  has_many :condition_groups

  def condition_group_classification_for(assets)
    Hash[assets.map{|asset| [asset, condition_groups_for(asset)]}]
  end

  def compatible_with?(assets)
    # Every asset has at least one condition group satisfied
    classification = condition_group_classification_for(assets)

    (classification.values.all? do |condition_group|
      ([condition_group].flatten.length==1)
    end) && (classification.values.flatten.uniq.length == condition_groups.length)
  end

  def condition_groups_for(asset)
    condition_groups.select do |condition_group|
      condition_group.conditions_compatible_with?(asset)
    end
  end
end
