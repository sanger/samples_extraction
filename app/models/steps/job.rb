module Steps::Job

  def asset_group_for_execution
    AssetGroup.create!(:assets => asset_group.assets)
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :step_type => step_type,
      #:asset_group => asset_group_for_execution
    })
    delay.perform_job      
  end

  def output_error(exception)
    [exception.message, Rails.backtrace_cleaner.clean(exception.backtrace)].flatten.join("\n")
  end

  def perform_job
    assign_attributes(state: 'running', output: nil)
    @error = nil
    begin
      process
    rescue StandardError => e 
      @error = e
    else
      @error=nil
      update_attributes!(:state => 'complete')
    end
  ensure
    # We publish to the clients that there has been a change in these assets
    asset_group.touch
    if activity
      activity.asset_group.touch unless state == 'complete'
    end

    # TODO:
    # This update needs to happen AFTER publishing the changes to the clients (touch), altough
    # is not clear for me why at this moment. Need to revisit it.
    unless state == 'complete'
      update_attributes!(:state => 'error', output: output_error(@error)) 
    end
  end

end