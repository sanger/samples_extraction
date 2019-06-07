module StepExecutionProcess
  def run
    return false unless compatible?
    plan
    apply
  end

end

