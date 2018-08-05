module Steps::WebsocketEvents
  def self.included(klass)
    klass.instance_eval do
      after_update :unset_activity_running, if: :can_unset_activity_running?
      after_update :wss_event      
    end
  end

  def can_unset_activity_running?
    (self.kind_of?(BackgroundSteps::BackgroundStep) && completed? && next_step.nil? && activity)
  end

  def unset_activity_running
    activity.in_progress!
    activity.touch
  end

  def wss_event
    activity.touch if activity
    return if !asset_group || asset_group.assets.empty?

    asset_group.touch
    asset_group.assets.map do |asset|
      asset.asset_groups.joins(:activity_owner).each(&:touch)
    end
  end

end