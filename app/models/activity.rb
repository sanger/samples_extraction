require 'date'

class Activity < ActiveRecord::Base

  validates :activity_type, :presence => true
  #validates :asset_group, :presence => true
  belongs_to :activity_type
  belongs_to :instrument
  belongs_to :kit
  has_many :owned_asset_groups, :class_name => 'AssetGroup', :foreign_key => 'activity_owner_id'
  has_many :steps
  has_many :step_types, :through => :activity_type
  has_many :uploads
  belongs_to :asset_group
  has_many :users, :through => :steps
  has_one :work_order

  scope :for_assets, ->(assets) { joins(:asset_group => :assets).where(:asset_group => {
    :asset_groups_assets=> {:asset_id => assets }
    })
  }

  scope :for_activity_type, ->(activity_type) {
    where(:activity_type => activity_type)
  }

  scope :for_user, ->(user) { joins(:steps).where({:steps => {:user_id => user.id}}).distinct }

  include Activities::StepsManagement
  include Activities::Tasks
  include Activities::BackgroundTasks
  include Activities::JsonAttributes
  include Activities::State
  include Activities::WebsocketEvents


end
