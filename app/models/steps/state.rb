module Steps::State
  def self.included(klass)
    klass.instance_eval do
      scope :in_progress, ->() { where(:in_progress? => true)}
      scope :cancelled, ->() {where(:state => 'cancel')}
      scope :running, ->() { where(state: 'running').includes(:operations, :step_type)}
      scope :pending, ->() { where(state: nil)}
      scope :failed, ->() { where(state: 'error')}
      scope :active, ->() { where("state = 'running' OR state = 'error' OR state IS NULL") }
      scope :finished, ->() { where("state != 'running' AND state IS NOT NULL").includes(:operations, :step_type)}
      scope :in_activity, ->() { where.not(activity_id: nil)}

      before_save :set_start_timestamp!, :if => [:running?, :state_changed?]
      before_save :set_complete_timestamp!, :if => [:completed?, :state_changed?]
    end
  end

  def set_start_timestamp!
    update_attributes(started_at: Time.now.utc) if started_at.nil?
  end

  def set_complete_timestamp!
    update_attributes(finished_at: Time.now.utc) if finished_at.nil?
  end

  def active?
    ((self.state == 'running') || (self.state.nil?))
  end

  def completed?
    (self.state == 'complete')
  end

  def cancelled?
    (self.state == 'cancel')
  end

  def failed?
    (self.state == 'error')
  end

  def running?
    (self.state == 'running')
  end

end