module Steps::ExecutionErrors
  class RelationCardinality < StandardError
  end

  class RelationSubject < StandardError
  end

  class UnknownConditionGroup < StandardError
  end  
end