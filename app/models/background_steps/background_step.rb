class BackgroundSteps::BackgroundStep < Step
  after_save :run_next_step, if: :can_run_next_step?

  def is_background_step?
    true
  end

  def run_next_step
    next_step.execute_actions
  end

  def can_run_next_step?
    complete? && next_step && !next_step.complete?
  end

end