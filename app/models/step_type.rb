class StepType < ActiveRecord::Base
  has_many :activity_type_step_types
  has_many :activity_types, :through => :activity_type_step_types
  has_many :condition_groups
  has_many :actions

  def condition_group_classification_for(assets)
    Hash[assets.map{|asset| [asset, condition_groups_for(asset)]}]
  end

  def every_condition_group_has_at_least_one_asset?(classification)
    (classification.values.flatten.uniq.length == condition_groups.length)
  end

  def every_asset_has_at_least_one_condition_group?(classification)
    (classification.values.all? do |condition_group|
      ([condition_group].flatten.length==1)
    end)
  end

  def every_required_asset_is_in_classification?(classification, required_assets)
    return true if required_assets.nil?
    required_assets.all?{|asset| !classification[asset].empty?}
  end

  def compatible_with?(assets, required_assets=nil)
    # Every asset has at least one condition group satisfied
    classification = condition_group_classification_for(assets)
    every_condition_group_has_at_least_one_asset?(classification) &&
      every_required_asset_is_in_classification?(classification, required_assets)
  end

  def condition_groups_for(asset)
    condition_groups.select do |condition_group|
      condition_group.conditions_compatible_with?(asset)
    end
  end

  def actions_for_condition_group(condition_group)
  end

  def actions_for(assets)
    #condition_group_classification_for(assets)
  end
end
