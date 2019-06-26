module Steps::Stoppable
  def self.included(klass)
    klass.instance_eval do
      before_update :check_stop
    end
  end

  def check_stop
    if (state == 'stopping') && (state_was == 'complete')
      # We cannot stop a step that has already happened
      self.state = 'complete'
      # We try to catch the next steps if we can
      delay.on_stopping_rest
    elsif (state == 'stopping') && (state_was != 'stopping')
      delay.on_stopping_me_and_rest
    elsif (state == 'continuing') && (state_was == 'stop')
      delay.on_continue
    end
  end

  def on_continue
    activity.steps.newer_than(self).stopped.update_all(state: nil)
    deprecate_unused_previous_steps!
    execute_actions
  end

  def on_stopping_rest
    activity.steps.newer_than(self).active.update_all(state: 'stop')
  end

  def on_stopping_me_and_rest
    on_stopping_rest
    on_cancel(false) if cancellable?
    self.state = 'stop'
  end
end
