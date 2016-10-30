module StepExecution::OperationActions

  def create_operation(asset, fact)
    Operation.create!(:action => action, :step => step,
      :asset=> asset, :predicate => fact.predicate, :object => fact.object)
  end

end
