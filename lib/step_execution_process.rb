module StepExecutionProcess
  def run
    return false unless compatible?
    inference
    export
    true
  end

end
