module Steps::WebsocketEvents
  def self.included(klass)
    klass.instance_eval do
      after_update :unset_activity_running, if: :can_unset_activity_running?
      after_update :wss_event
    end
  end

  def can_unset_activity_running?
    (self.kind_of?(Activities::BackgroundTasks::BackgroundStep) && completed? && next_step.nil? && activity)
  end

  def unset_activity_running
    activity.in_progress!
    activity.touch
  end

  def wss_event
    activity.touch if activity
    asset_group.touch if asset_group
    asset_groups_affected.each(&:touch)
  end

end
