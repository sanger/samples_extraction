module Steps::Cancellable
  def self.included(klass)
    klass.instance_eval do
      scope :newer_than, ->(step) { where("id > #{step.id}").includes(:operations, :step_type)}
      scope :older_than, ->(step) { where("id < #{step.id}").includes(:operations, :step_type)}

      before_update :modify_related_steps

    end
  end

  def cancellable?
    true
  end

  def modify_related_steps
    if (state == 'cancel' && (state_was == 'complete' || state_was == 'error'))
      on_cancel
    elsif state == 'complete' && state_was =='cancel'
      on_remake
    end
  end

  def steps_newer_than_me
    activity.steps.newer_than(self)
  end

  def steps_older_than_me
    activity.steps.older_than(self)
  end

  def on_cancel
    changes = [
      fact_changes_for_option(:cancel),
      steps_newer_than_me.completed.map{|s| s.fact_changes_for_option(:cancel)}
    ].flatten.reduce(FactChanges.new) do |memo, updates|
      memo.merge(updates)
    end

    ActiveRecord::Base.transaction do
      changes.apply(self, false)
      steps_newer_than_me.completed.update_all(state: 'cancel')
      operations.update_all(cancelled?: true)
    end
    wss_event
  end

  def on_remake
    changes = [
      steps_older_than_me.cancelled.map{|s| s.fact_changes_for_option(:remake)},
      fact_changes_for_option(:remake)
    ].flatten.reduce(FactChanges.new) do |memo, updates|
      memo.merge(updates)
    end

    ActiveRecord::Base.transaction do
      changes.apply(self, false)
      steps_older_than_me.cancelled.update_all(state: 'complete')
      operations.update_all(cancelled?: false)
    end

    wss_event
  end

  def fact_changes_for_option(option_name)
    operations.reduce(FactChanges.new) do |updates, operation|
      operation.generate_changes_for(option_name, updates)
      updates
    end
  end

  def cancelled?
    state == 'cancel'
  end

  def _change_state(state)
    update_attributes(:state => state)
  end

  def cancel
    delay._change_state('cancel')
  end

  def remake
    delay._change_state('complete')
  end
end
