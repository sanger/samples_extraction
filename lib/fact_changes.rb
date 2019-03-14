class FactChanges
  attr_accessor :facts_to_destroy, :facts_to_add

  def initialize
    reset
  end

  def reset
    @facts_to_destroy = []
    @facts_to_add = []
  end

  def add(s,p,o, options=nil)
    facts_to_add.push([s,p,o, options]) if (s && p && o)
  end

  def add_remote(s,p,o)
    add(s,p,o,is_remote?: true)
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
      remove_facts(step, facts_to_destroy.flatten)
      create_facts(step, facts_to_add)
      reset
    end
  end

  private

  def create_facts(step, triples)
    facts = triples.map do |t|
      params = {asset: t[0], predicate: t[1], literal: !(t[2].kind_of?(Asset))}
      params[:literal] ? params[:object] = t[2] : params[:object_asset] = t[2]
      params = params.merge(t[3]) if t[3]
      Fact.new(params) unless Fact.exists?(params)
    end.compact
    Fact.import(facts)
    add_operations(step, facts)
  end

  def remove_facts(step, facts)
    facts = [facts].flatten
    ids_to_remove = facts.map(&:id).compact
    remove_operations(step, facts)
    Fact.where(id: ids_to_remove).delete_all if ids_to_remove && !ids_to_remove.empty?
  end

  def add_operations(step, facts)
    operations = facts.map do |fact|
      Operation.new(:action_type => 'addFacts', :step => step,
        :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object, object_asset: fact.object_asset)
    end
    Operation.import(operations)
  end

  def remove_operations(step, facts)
    operations = facts.map do |fact|
      Operation.new(:action_type => 'removeFacts', :step => step,
        :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object, object_asset: fact.object_asset)
    end
    Operation.import(operations)
  end

end
