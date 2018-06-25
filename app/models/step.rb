
class Step < ActiveRecord::Base

  include Steps::Cancellable
  include Deprecatable

  #after_update :sse_event

  after_update :wss_event
  
  include QueueableJob
  after_update :unset_activity_running, if: :can_unset_activity_running?

  def can_unset_activity_running?
    (self.kind_of?(BackgroundSteps::BackgroundStep) && complete? && next_step.nil?)
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

    return
    asset_group.assets.map(&:asset_groups).flatten.uniq.each do |agroup|
      assets_from_step = asset_group.assets & agroup.assets
      list=[]
      if (state == 'running')
        data = {state: 'running', assets: assets_from_step.map(&:uuid)}
      else
        data = {state: 'hanged', assets: assets_from_step.map(&:uuid)}
        #if previous_changes[:state]=='running'
        #  data = {state: 'hanged', assets: assets_from_step.map(&:uuid)}
        #end
      end
      if (data && !data[:assets].empty?)
        ActionCable.server.broadcast("asset_group_#{asset_group.id}", {assets_status: data})
      end
    end
  end

  def sse_event
    if (state == 'running')
      asset_group.assets.each do |asset|
        SseRailsEngine.send_event('asset_running', {state: 'running', uuid: asset.uuid})
      end
    else
      if previous_changes[:state]=='running'
        asset_group.assets.each do |asset|
          SseRailsEngine.send_event('asset_running', {state: 'hanged', uuid: asset.uuid})
        end
      end
    end
  end


  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  belongs_to :user
  has_many :uploads
  has_many :operations

  has_many :assets, through: :asset_group

  scope :running_with_asset, ->(asset) { includes(:assets).where(asset_groups_assets: { asset_id: asset.id}, state: 'running') }

  belongs_to :created_asset_group, :class_name => 'AssetGroup', :foreign_key => 'created_asset_group_id'

  scope :in_progress, ->() { where(:in_progress? => true)}
  scope :cancelled, ->() {where(:state => 'cancel')}
  scope :running, ->() { where(state: 'running').includes(:operations, :step_type)}
  scope :pending, ->() { where(state: nil)}
  scope :active, ->() { where("state = 'running' OR state IS NULL").includes(:operations, :step_type)}
  scope :finished, ->() { where("state != 'running' AND state IS NOT NULL").includes(:operations, :step_type)}
  scope :in_activity, ->() { where.not(activity_id: nil)}

  before_create :assets_compatible_with_step_type, :unless => :in_progress?
  after_create :deprecate_cancelled_steps
  after_create :execute_actions, :if => :can_run_now?


  self.inheritance_column = :sti_type
  belongs_to :next_step, class_name: 'Step', :foreign_key => 'next_step_id'

  serialize :printer_config


  def can_run_now?
    !is_background_step? && !in_progress?
  end

  def is_background_step?
    false
  end

  def deprecate_cancelled_steps
    if activity
      activity.steps.cancelled.each do |s|
        s.deprecate_with(self)
      end
    end
  end

  def after_deprecate
    update_attributes(:state => 'deprecated', :activity => nil)
  end

  class RelationCardinality < StandardError
  end

  class RelationSubject < StandardError
  end

  class UnknownConditionGroup < StandardError
  end

  scope :for_assets, ->(assets) { joins(:asset_group => :assets).where(:asset_groups_assets =>  {:asset_id => assets })}


  scope :for_step_type, ->(step_type) { where(:step_type => step_type)}

  attr_accessor :wildcard_values


  def assets_compatible_with_step_type
    checked_condition_groups=[], @wildcard_values = {}
    compatible = step_type.compatible_with?(asset_group_assets, nil, checked_condition_groups, wildcard_values)
    raise StandardError unless compatible || (asset_group_assets.count == 0)
  end

  def asset_group_assets
    asset_group ? asset_group.assets : []
  end

  def add_facts(asset, facts)
    facts = [facts].flatten
    asset.add_facts(facts)
    asset.add_operations(facts, self)
  end

  def remove_facts(asset, facts)
    facts = [facts].flatten
    asset.remove_facts(facts)
    asset.remove_operations(facts, self)
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

  def execute_actions
    original_assets = AssetGroup.create!
    if ((activity) && (activity.asset_group.assets.count >= 0))
      original_assets.add_assets(activity.asset_group.assets)
    else
      original_assets.add_assets(asset_group_assets)
    end

    step_execution = build_step_execution(:facts_to_destroy => [], :original_assets => original_assets.assets)

    ActiveRecord::Base.transaction do |t|
      activate!

      step_execution.run

      unselect_assets_from_antecedents

      Fact.where(:id => step_execution.facts_to_destroy.flatten.compact.map(&:id)).delete_all

      #update_assets_started if activity

      unselect_assets_from_consequents
      deactivate
    end
    update_attributes(:asset_group => original_assets) if activity
    update_attributes(:state => 'running')
  end

  def update_assets_started
    activity.asset_group.assets.not_started.each do |asset|
      asset.add_facts(Fact.create(:predicate => 'is', :object => 'Started'))
      asset.facts.where(:predicate => 'is', :object => 'NotStarted').each(&:destroy)
    end
  end

  def progress_with(step_params)
    original_assets = activity.asset_group.assets
    ActiveRecord::Base.transaction do |t|
      activate! unless active?
      assets = step_params[:assets]
      update_attributes(:in_progress? => true)

      asset_group.add_assets(assets) if assets

      step_execution = build_step_execution(
        :original_assets => original_assets,
        :facts_to_destroy => nil)
      step_execution.run

      asset_group.update_attributes(:assets => [])
      finish if step_params[:state]=='done'
    end
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
      deactivate
    end
    asset_group_assets.each(&:touch)
  end

  include Lab::Actions

  def service_update_hash(asset, depth=0)
    raise 'Too many recursion levels' if (depth > 5)
    [asset.facts.literals.map do |f|
      {
        predicate_to_property(f.predicate) => f.object
      }
    end,
    asset.facts.not_literals.map do |f|
      {
        predicate_to_property(f.predicate) => service_update_hash(f.object_asset_id, depth+1)
      }
    end].flatten.merge
  end

  def activate!
    #unless activity.nil?
    #  unless (active? || activity.active_step.nil?)
    #    raise 'Another step is already active for this activity'
    #  end
    #  activity.update_attributes!(:active_step => self)
    #end
  end

  def active?
    return false if activity.nil?
    activity.active_step == self
  end

  def complete?
    (state == 'complete')
  end

  def cancelled?
    (state == 'cancel')
  end

  def failed?
    (state == 'error')
  end


  def deactivate
    #activity.update_attributes!(:active_step => nil) unless activity.nil?
  end

end
