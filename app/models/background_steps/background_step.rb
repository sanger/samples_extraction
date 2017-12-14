class BackgroundSteps::BackgroundStep < Step
  after_initialize :set_step_type  
  after_update :run_next_step, if: :can_run_next_step?
  after_commit :perform_error, if: :has_error?

  class BackgroundSteps::BackgroundStep::ErrorOnProcess < StandardError
  end

  def is_background_step?
    true
  end

  def has_error?
    state == 'error'
  end

  def perform_error
    raise BackgroundSteps::BackgroundStep::ErrorOnProcess
  end

  def run_next_step
    next_step.execute_actions
  end

  def can_run_next_step?
    complete? && next_step && !next_step.complete?
  end

  def set_step_type
    update_attributes(step_type: StepType.find_or_create_by(:name => self.class.to_s )) if step_type.nil?
  end

end