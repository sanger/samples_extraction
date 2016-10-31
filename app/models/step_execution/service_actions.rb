module StepExecution::ServiceActions
  def update_service
    asset.update_attributes(:mark_to_update => true)
  end
end
