module Steps::ExecutionActions
  def self.included(klass)
    klass.instance_eval do
      before_create :assets_compatible_with_step_type, :unless => [:in_progress?]
      after_update :on_complete, :if => [:completed?, :saved_change_to_state?]
    end
  end



  def can_run_now?
    !is_background_step? && !in_progress?
  end

  def is_background_step?
    false
  end

  def assets_compatible_with_step_type
    return true if asset_group.nil?
    checked_condition_groups=[], @wildcard_values = {}
    compatible = step_type.compatible_with?(asset_group_assets, nil, checked_condition_groups, wildcard_values)
    raise StandardError unless compatible || (asset_group_assets.count == 0)
  end

  def unselect_assets_from_antecedents
    asset_group.unselect_assets_with_conditions(step_type.condition_groups) unless asset_group.nil?
    if activity
      activity.asset_group.unselect_assets_with_conditions(step_type.condition_groups)
    end
  end

  def unselect_assets_from_consequents
    unless asset_group.nil?
      asset_group.unselect_assets_with_conditions(step_type.action_subject_condition_groups)
      asset_group.unselect_assets_with_conditions(step_type.action_object_condition_groups)
    end
    if activity
      activity.asset_group.unselect_assets_with_conditions(step_type.action_subject_condition_groups)
      activity.asset_group.unselect_assets_with_conditions(step_type.action_object_condition_groups)
    end
  end

  def build_step_execution(params)
    StepExecution.new({
        :step => self,
        :asset_group => asset_group,
        :created_assets => {}
      }.merge(params))
  end

  def execute_step_action
    send(step_type.step_action)
    return self
  end

  def asset_group_assets
    asset_group ? asset_group.assets : []
  end

  def process
    if activity
      activity.touch
      activity.save
    end
    return execute_step_action if step_type.step_action

    running_asset_group = AssetGroup.create!(assets: asset_group_assets)

    step_execution = build_step_execution(:facts_to_destroy => [], :original_assets => running_asset_group.assets)
    ActiveRecord::Base.transaction do |t|

      step_execution.run

      unselect_assets_from_antecedents

      Fact.where(:id => step_execution.facts_to_destroy.flatten.compact.map(&:id)).delete_all

      unselect_assets_from_consequents
    end
    update_attributes(:asset_group => running_asset_group) if activity
    update_attributes(:state => 'running')
  end

  def progress_with(assets, state = nil)
    original_assets = activity.asset_group.assets
    ActiveRecord::Base.transaction do |t|
      update_attributes(:in_progress? => true)

      asset_group.add_assets(assets) if assets

      step_execution = build_step_execution(
        :original_assets => original_assets,
        :facts_to_destroy => nil)
      step_execution.run

      asset_group.update_attributes(:assets => [])
      finish if (state=='done')
    end
  end

  def on_complete
    assets_to_notice = []

    facts_to_remove = Fact.where(:to_remove_by => self.id)
    assets_to_notice.concat(facts_to_remove.map(&:asset).uniq.compact) if facts_to_remove

    facts_to_add = Fact.where(:to_add_by => self.id)
    assets_to_notice.push(facts_to_add.map(&:asset).uniq.compact).flatten if facts_to_add
    ActiveRecord::Base.transaction do |t|
      facts_to_remove.delete_all if facts_to_remove
      facts_to_add.update_all(:to_add_by => nil) if facts_to_add
      assets_to_notice.flatten.compact.each(&:touch) if assets_to_notice
    end
    true
  end

  def finish
    ActiveRecord::Base.transaction do |t|
      unselect_assets_from_antecedents
      facts_to_remove = Fact.where(:to_remove_by => self.id)
      facts_to_remove.map(&:asset).uniq.compact.each(&:touch)
      #facts_to_remove.each do |fact|
      #  operation = Operation.create!(:action_type => 'removeFacts', :step => self,
      #      :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object)
      #end
      facts_to_remove.delete_all
      facts_to_add = Fact.where(:to_add_by => self.id)
      facts_to_add.map(&:asset).uniq.compact.each(&:touch)
      #facts_to_add.each do |fact|
      #  operation = Operation.create!(:action_type => 'addFacts', :step => self,
      #      :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object)
      #end
      facts_to_add.update_all(:to_add_by => nil)
      unselect_assets_from_consequents


      update_attributes(:in_progress? => false)
      update_attributes(:state => 'running')
    end
    asset_group_assets.each(&:touch)
  end



end
