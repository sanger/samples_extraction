module Steps::Stoppable
  def stop_job
    ActiveRecord::Base.transaction do
      Delayed::Job.find(self.job_id).destroy if self.job_id
      clear_job
    end
  end

  def continue_newer_steps
    activity.steps.newer_than(self).stopped.each(&:continue!)
  end

  def stop_newer_steps
    activity.steps.newer_than(self).active.each(&:stop!)
  end

end
