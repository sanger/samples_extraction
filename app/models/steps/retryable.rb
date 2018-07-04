module Steps::Retryable
  def self.included(klass)
    klass.instance_eval do
      before_update :check_retry
    end
  end

  def check_retry
    if ((state == 'retry') && (state_was == 'error'))
      on_retry
    end
  end

  def on_retry
    job.invoke_job
  end
end