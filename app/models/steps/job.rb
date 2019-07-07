module Steps::Job

  def create_job
    created_job = delay(queue: 'steps').perform_job
    created_job.save
    self.job_id = created_job.id
    save!
  end

  def clear_job
    self.job_id = nil
    @error=nil
    save!
  end

  def save_error_output
    self.output = output_error(@error)
    self.job_id = job ? job.id : nil
    save!
  end

  def output_error(exception)
    return output unless exception
    [
      output, exception && exception.message,
      Rails.backtrace_cleaner.clean(exception && exception.backtrace)
    ].flatten.join("\n")
  end

  def job
    job_id ? Delayed::Job.find(job_id) : nil
  end

  def perform_job
    @error = nil
    begin
      process
    rescue StandardError => e
      @error = e
      true
    else
      complete!
      #@error=nil
      #update_attributes!(state: 'complete', job_id: nil)
    end
  ensure
    # We publish to the clients that there has been a change in these assets
    wss_event

    # TODO:
    # This update needs to happen AFTER publishing the changes to the clients (touch), although
    # is not clear for me why at this moment. Need to revisit it.
    unless completed?
      fail!
    end
    #unless state == 'complete'
    #  update_attributes(state: 'error', output: output_error(@error), job_id: job ? job.id : nil)
    #end

  end

end
