require 'fact_changes'
class Callback
  def self.on_add_property(property_name, method)
    FactChanges.on_change_predicate('add_facts', property_name, Proc.new do |tuple, updates, step|
      send(method, tuple, updates, step)
    end)
  end

  def self.on_remove_property(property_name, method)
    FactChanges.on_change_predicate('remove_facts', property_name, Proc.new do |tuple, updates, step|
      send(method, tuple, updates, step)
    end)
  end

  def self.on_keep_property(property_name, method)
    FactChanges.on_keep_predicate(property_name, Proc.new do |tuple, updates, step|
      send(method, tuple, updates, step)
    end)
  end

end
