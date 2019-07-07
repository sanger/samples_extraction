module QueueableJob
  extend ActiveSupport::Concern

  included do
    after_update :run_next_step, if: :can_run_next_step?
    after_commit :perform_error, if: :has_error?
  end

  class ErrorOnQueuedJobProcess < StandardError
  end

  def has_error?
    state == 'error'
  end

  def perform_error
    raise @error if @error
  end

  def run_next_step
    next_step.run
  end

  def can_run_next_step?
    activity && activity.running? && completed? && next_step && !next_step.completed? && !next_step.running?
  end

end
