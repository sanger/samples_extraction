class Condition < ActiveRecord::Base
  belongs_to :condition_group
  has_many :activity_types, :through => :condition_group
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  def compatible_with?(asset, related_assets = [], checked_condition_groups=[])
    asset.facts.any? do |fact|
      # Either objects are equal, or both of them are relations to something. We
      # do not check the relations values, because we consider them as wildcards
      if object_condition_group_id.nil? || fact.object_asset_id.nil?
        ((fact.predicate == predicate) && (fact.object == object))
      else
        cg = ConditionGroup.find(object_condition_group_id)
        related_asset = Asset.find(fact.object_asset_id)

        # This condition does not support evaluating relations like:
        # ?a :t ?b . ?b :t ?c . ?c :t ?a .
        # because it end up in a loop (SystemStackError). To fix this, from ConditionGroup
        # we would need to pass as an argument the list of condition_groups valid up to
        # this point, in which the only thing we need to validate is the object in the relations.
        # For the moment these types of relations will remain unsupported
        if checked_condition_groups.include?(cg)
          compatible = (fact.predicate == predicate)
        else
          checked_condition_groups << cg
          compatible = ((fact.predicate == predicate) && cg.compatible_with?(related_asset, related_assets, checked_condition_groups))
        end
        related_assets.push(related_asset) if compatible
        compatible
      end
    end
  end
end
