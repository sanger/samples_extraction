class Condition < ActiveRecord::Base
  belongs_to :condition_group
  has_many :activity_types, :through => :condition_group
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  def check_wildcard_condition(asset, wildcard_values={})
    cg = object_condition_group

    # If the condition group is a wildcard, we'll cache all the possible
    # values and check compatibility with other definitions of the same
    # wildcard.
    facts = asset.facts.with_predicate(predicate)
    return false if facts.count == 0
    actual_values = facts.map(&:object_value)
    if wildcard_values[cg.id].nil?
      wildcard_values[cg.id] = actual_values
    else
      wildcard_values[cg.id] &= actual_values
      return false if wildcard_values[cg.id].empty?
    end
    return true
  end

  def check_related_condition_group(cg, fact, related_assets = [], checked_condition_groups=[], wildcard_values={})
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
      compatible = ((fact.predicate == predicate) && cg.compatible_with?(related_asset, related_assets, checked_condition_groups, wildcard_values))
    end
    related_assets.push(related_asset) if compatible
    compatible
  end

  def is_wildcard_condition?
    return object_condition_group && object_condition_group.is_wildcard?
  end

  def compatible_with?(asset, related_assets = [], checked_condition_groups=[], wildcard_values = {})
    return check_wildcard_condition(asset, wildcard_values) if is_wildcard_condition?
    asset.facts.any? do |fact|
      # Either objects are equal, or both of them are relations to something. We
      # do not check the relations values, because we consider them as wildcards
      if object_condition_group_id.nil? || fact.object_asset_id.nil?
        ((fact.predicate == predicate) && (fact.object == object))
      else
        cg = ConditionGroup.find(object_condition_group_id)
        check_related_condition_group(cg, fact, related_assets,
  	  checked_condition_groups, wildcard_values)
      end
    end
  end
end
