class Condition < ActiveRecord::Base
  belongs_to :condition_group
  has_many :activity_types, :through => :condition_group

  def compatible_with?(asset)
    asset.facts.any? do |fact|
      (fact.predicate == predicate) && (fact.object == object)
    end
  end
end
