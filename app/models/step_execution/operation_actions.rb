module StepExecution::OperationActions
  def store_operations
    if changed_assets && changed_facts
      changed_assets.each do |asset|
        changed_facts.each do |fact|
          operation = Operation.create!(:action => action, :step => step,
            :asset=> asset, :predicate => fact.predicate, :object => fact.object)
        end
      end
    end
  end
end
