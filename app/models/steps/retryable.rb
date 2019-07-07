module Steps::Retryable

  def on_retrying
    if ((state == 'retrying') && (state_was == 'error'))
      delay(queue: 'steps').on_retry
    end
  end

  def on_retry
    ActiveRecord::Base.transaction do
      job.update_attributes(run_at: job.created_at)
    end
  end
end
