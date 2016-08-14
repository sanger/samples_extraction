class Condition < ActiveRecord::Base
  belongs_to :condition_group
  has_many :activity_types, :through => :condition_group

  def compatible_with?(asset)
    asset.facts.any? do |fact|
      # Either objects are equal, or both of them are relations to something. We
      # do not check the relations values, because we consider them as wildcards
      if object_condition_group_id.nil? || fact.object_asset_id.nil?
        ((fact.predicate == predicate) && (fact.object == object))
      else
        cg = ConditionGroup.find(object_condition_group_id)
        related_asset = Asset.find(fact.object_asset_id)
        compatible = ((fact.predicate == predicate) && cg.compatible_with?(related_asset))
        condition_group.step_type.related_assets.push(related_asset) if compatible
        compatible
      end
    end
  end
end
