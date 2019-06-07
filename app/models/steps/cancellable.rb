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
      delay.on_cancel
    elsif state == 'complete' && state_was =='cancel'
      delay.on_remake
    end
  end

  def steps_newer_than_me
    activity.steps.newer_than(self)
  end

  def steps_older_than_me
    activity.steps.older_than(self)
  end

  def on_cancel
    ActiveRecord::Base.transaction do
      fact_changes_for_option(:cancel).apply(self, false)
      steps_newer_than_me.completed.each do |s|
        s.fact_changes_for_option(:cancel).apply(s, false)
      end
      steps_newer_than_me.completed.update_all(state: 'cancel')
      operations.update_all(cancelled?: true)
    end
    wss_event
  end

  def on_remake
    ActiveRecord::Base.transaction do
      steps_older_than_me.cancelled.each do |s|
        s.fact_changes_for_option(:remake).apply(s, false)
      end
      steps_older_than_me.cancelled.update_all(state: 'complete')
      fact_changes_for_option(:remake).apply(self, false)
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

  def cancel
    update_attributes(:state => 'cancel')
  end

  def remake
    update_attributes(:state => 'complete')
  end
end
