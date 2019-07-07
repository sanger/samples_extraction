module Steps::Stoppable
  def on_stopping
    if (state == 'stopping') && (state_was == 'complete')
      # We cannot stop a step that has already happened
      self.state = 'complete'
      # We try to catch the next steps if we can
      delay(queue: 'steps').on_stopping_rest
    elsif (state == 'stopping') && (state_was != 'stop')
      delay(queue: 'steps').on_stopping_me_and_rest
    elsif (state == 'continuing') && (state_was == 'stop')
      delay(queue: 'steps').on_continue
    end
  end

  def continue_newer_steps
    activity.steps.newer_than(self).stopped.each(&:continue!)
  end

  def stop_newer_steps
    activity.steps.newer_than(self).active.each(&:stop!)
  end

end
