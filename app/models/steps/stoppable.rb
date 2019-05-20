module Steps::Stoppable
  def self.included(klass)
    klass.instance_eval do
      before_update :check_stop
    end
  end

  def check_stop
    if (state == 'stop') && (state_was == 'complete')
      # We cannot stop a step that has already happened
      self.state = 'complete'
      # We try to catch the next steps if we can
      on_stop
    elsif (state == 'stop')
      on_stop
    elsif (state == 'complete') && (state_was == 'stop')
      on_continue
    end
  end

  def on_continue
    activity.steps.newer_than(self).stopped.update_all(state: nil)
    deprecate_unused_previous_steps!
    execute_actions
  end

  def on_stop
    activity.steps.newer_than(self).active.update_all(state: 'stop')
  end
end
