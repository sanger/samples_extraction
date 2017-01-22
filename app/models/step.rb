class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  belongs_to :user
  has_many :uploads
  has_many :operations

  belongs_to :created_asset_group, :class_name => 'AssetGroup', :foreign_key => 'created_asset_group_id'

  scope :in_progress, ->() { where(:in_progress? => true)}

  after_create :execute_actions, :unless => :in_progress?

  before_create :assets_compatible_with_step_type, :unless => :in_progress?

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
    compatible = step_type.compatible_with?(asset_group.assets, nil, checked_condition_groups, wildcard_values)
    raise StandardError unless compatible || (asset_group.assets.count == 0)
  end

  def unselect_assets_from_antecedents
    asset_group.unselect_assets_with_conditions(step_type.condition_groups)
    if activity
      activity.asset_group.unselect_assets_with_conditions(step_type.condition_groups)
    end
  end

  def unselect_assets_from_consequents
    asset_group.unselect_assets_with_conditions(step_type.action_subject_condition_groups)
    asset_group.unselect_assets_with_conditions(step_type.action_object_condition_groups)
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
    return progress_with(asset_group.assets) if in_progress?

    original_assets = AssetGroup.create!
    if ((activity) && (activity.asset_group.assets.count >= 0))
      original_assets.add_assets(activity.asset_group.assets)
    else
      original_assets.add_assets(asset_group.assets)
    end
    ActiveRecord::Base.transaction do |t|
      activate!
      step_execution = build_step_execution(:facts_to_destroy => [], :original_assets => original_assets.assets)

      step_execution.run

      unselect_assets_from_antecedents

      Fact.where(:id => step_execution.facts_to_destroy.flatten.compact.map(&:id)).delete_all

      #update_assets_started if activity

      unselect_assets_from_consequents
      update_service
      deactivate
    end
    update_attributes(:asset_group => original_assets) if activity
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

      asset_group.add_assets(assets)

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
      #facts_to_remove.each do |fact|
      #  operation = Operation.create!(:action_type => 'removeFacts', :step => self,
      #      :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object)
      #end
      facts_to_remove.delete_all
      facts_to_add = Fact.where(:to_add_by => self.id)
      #facts_to_add.each do |fact|
      #  operation = Operation.create!(:action_type => 'addFacts', :step => self,
      #      :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object)
      #end
      facts_to_add.update_all(:to_add_by => nil)
      unselect_assets_from_consequents

      update_service

      update_attributes(:in_progress? => false)
      deactivate
    end
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
    unless (active? || activity.active_step.nil?)
      raise 'Another step is already active for this activity'
    end
    activity.update_attributes!(:active_step => self)
  end

  def active?
    activity.active_step == self
  end

  def deactivate
    activity.update_attributes!(:active_step => nil)
  end

  def update_service
    #ActiveRecord::Base.transaction do |t|
    #  activity.asset_group.assets.marked_to_update.with_update_transformation.map do |a|
    #    service_update_hash(a)
    #  end
    #end
  end
end
