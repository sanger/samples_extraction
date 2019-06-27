module Steps::Retryable
  def self.included(klass)
    klass.instance_eval do
      before_update :check_retry
    end
  end

  def check_retry
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
