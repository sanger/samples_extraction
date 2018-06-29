class FactChanges
  attr_accessor :facts_to_destroy, :facts_to_add

  def initialize
    @facts_to_destroy = []
    @facts_to_add = []
  end

  def add(s,p,o)
    facts_to_add.push([s,p,o])
  end

  def remove(f)
    facts_to_destroy.push(f)
  end

  def merge(fact_changes)
    facts_to_add.concat(fact_changes.facts_to_add)
    facts_to_destroy.concat(fact_changes.facts_to_destroy)
    self
  end

  def apply(step)
    ActiveRecord::Base.transaction do |t|
      step.remove_facts(facts_to_destroy.flatten)
      step.create_facts(facts_to_add)
    end
  end
end
