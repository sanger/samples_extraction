module Steps::Cancellable
  def self.included(klass)
    klass.instance_eval do
      scope :newer_than, ->(step) { where("id > #{step.id}").includes(:operations, :step_type)}
      scope :older_than, ->(step) { where("id < #{step.id}").includes(:operations, :step_type)}

      before_update :modify_related_steps
    end
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
      fact_changes_for_option(:cancel, self).apply(self, false)
      steps_newer_than_me.completed.each do |s|
        fact_changes_for_option(:cancel, s).apply(s, false)
      end
      steps_newer_than_me.completed.update_all(state: 'cancel')
      operations.update_all(cancelled?: true)
    end
    wss_event
  end

  def on_remake
    ActiveRecord::Base.transaction do
      steps_older_than_me.cancelled.each do |s|
        fact_changes_for_option(:remake, s).apply(s, false)
      end
      steps_older_than_me.cancelled.update_all(state: 'complete')
      fact_changes_for_option(:remake, self).apply(self, false)
      operations.update_all(cancelled?: false)
    end
    wss_event

    # ActiveRecord::Base.transaction do
    #   steps_older_than_me.cancelled.each do |s|
    #     s.remake if s.cancelled?
    #   end
    #   fact_changes_for_option(:remake).apply(self, false)
    #   operations.update_all(cancelled?: false)
    # end
    # wss_event
  end

  def fact_changes_for_option(option_name, step)
    step.operations.reduce(FactChanges.new) do |memo, operation|
      action_type = operation.action_type_for_option(option_name)
      if (action_type == :add_facts)
        memo.add(operation.asset, operation.predicate, operation.object_value)
      elsif (action_type == :remove_facts)
        memo.remove(Fact.where(asset: operation.asset, predicate: operation.predicate, object: operation.object, object_asset: operation.object_asset))
      elsif (action_type == :create_asset)
        asset = Asset.create(uuid: operation.object)
        operation.update_attributes(asset: asset)
        memo.create_assets([asset.uuid])
      elsif (action_type == :delete_asset)
        memo.delete_assets([operation.object])
      end
      memo
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
