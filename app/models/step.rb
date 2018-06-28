
class Step < ActiveRecord::Base

  self.inheritance_column = :sti_type

  attr_accessor :wildcard_values

  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  belongs_to :user
  has_many :uploads
  has_many :operations
  has_many :assets, through: :asset_group
  belongs_to :created_asset_group, :class_name => 'AssetGroup', :foreign_key => 'created_asset_group_id'
  belongs_to :next_step, class_name: 'Step', :foreign_key => 'next_step_id'

  serialize :printer_config

  scope :running_with_asset, ->(asset) { includes(:assets).where(asset_groups_assets: { asset_id: asset.id}, state: 'running') }
  scope :for_assets, ->(assets) { joins(:asset_group => :assets).where(:asset_groups_assets =>  {:asset_id => assets })}
  scope :for_step_type, ->(step_type) { where(:step_type => step_type)}  

  include QueueableJob
  include Steps::Cancellable
  include Steps::WebsocketEvents
  include Deprecatable  
  include Steps::Deprecatable
  include Steps::State
  include Steps::ExecutionActions
  include Lab::Actions

  def asset_group_assets
    asset_group ? asset_group.assets : []
  end

  def create_facts(triples)
    facts = triples.map do |t|
      params = {asset: t[0], predicate: t[1], literal: t[2].kind_of?(Asset)}
      params[:literal] ? params[:object_asset] = t[2] : params[:object] = t[2]
      Fact.create(params)
    end

    add_operations(facts)
  end

  def remove_facts(facts)
    facts = [facts].flatten
    ids_to_remove = facts.map(&:id).compact
    
    remove_operations(facts)
    Fact.where(id: ids_to_remove).delete_all if ids_to_remove && !ids_to_remove.empty?
  end  

  def add_operations(facts)
    facts.each do |fact|
      Operation.create!(:action_type => 'addFacts', :step => self,
        :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object, object_asset: fact.object_asset)
    end
  end

  def remove_operations(facts)
    facts.each do |fact|
      Operation.create!(:action_type => 'removeFacts', :step => self,
        :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object, object_asset: fact.object_asset)
    end
  end



end
