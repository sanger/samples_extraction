module Steps::Retryable
  def on_retrying
    delay(queue: 'steps').on_retry if ((state == 'retrying') && (state_was == 'error'))
  end

  def on_retry
    ActiveRecord::Base.transaction { job.update_attributes(run_at: job.created_at) }
  end
end
