require 'fact_changes'
class Callback

  def self.run_and_catch_any_errors(method, tuple, updates, step)
    begin
      send(method, tuple, updates, step)
    rescue StandardError => e
      updates.set_errors([e.message, e.backtrace.join.to_s])
    end
  end

  def self.on_add_property(property_name, method)
    FactChanges.on_change_predicate('add_facts', property_name, Proc.new do |tuple, updates, step|
      run_and_catch_any_errors(method, tuple, updates, step)
    end)
  end

  def self.on_remove_property(property_name, method)
    FactChanges.on_change_predicate('remove_facts', property_name, Proc.new do |tuple, updates, step|
      run_and_catch_any_errors(method, tuple, updates, step)
    end)
  end

  def self.on_keep_property(property_name, method)
    FactChanges.on_keep_predicate(property_name, Proc.new do |tuple, updates, step|
      run_and_catch_any_errors(method, tuple, updates, step)
    end)
  end

end
