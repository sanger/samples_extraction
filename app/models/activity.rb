# frozen_string_literal: true

require 'date'

# An Activity collects together a series of {Step steps} which were performed on
# an {AssetGroup}. The AssetGroup reflects the currently actively processed set
# of {Asset assets} so may be updated as the activity progresses.
class Activity < ApplicationRecord
  validates :activity_type, presence: true
  # validates :asset_group, :presence => true
  belongs_to :activity_type
  belongs_to :instrument
  belongs_to :kit
  has_many :owned_asset_groups, class_name: 'AssetGroup', foreign_key: 'activity_owner_id'
  has_many :steps
  has_many :step_types, through: :activity_type
  has_many :uploads
  belongs_to :asset_group, optional: true
  has_many :assets, through: :asset_group
  has_many :users, through: :steps
  has_one :work_order

  scope :for_activity_type, ->(activity_type) {
    where(activity_type: activity_type)
  }

  scope :for_user, ->(user) { joins(:steps).where({ :steps => { :user_id => user.id } }).distinct }

  include Activities::StepsManagement
  include Activities::Tasks
  include Activities::BackgroundTasks
  include Activities::JsonAttributes
  include Activities::State
  include Activities::WebsocketEvents

  delegate :name, to: :activity_type, prefix: true
  delegate :barcode, :type, to: :kit, prefix: true
  delegate :name, to: :instrument, prefix: true
  delegate :fullname, to: :last_user, prefix: true

  def last_user
    users.order('steps.created_at, steps.id DESC').first
  end
end
