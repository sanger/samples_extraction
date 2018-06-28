module Steps::State
  def self.included(klass)
    klass.instance_eval do
      scope :in_progress, ->() { where(:in_progress? => true)}
      scope :cancelled, ->() {where(:state => 'cancel')}
      scope :running, ->() { where(state: 'running').includes(:operations, :step_type)}
      scope :pending, ->() { where(state: nil)}
      scope :active, ->() { where("state = 'running' OR state IS NULL").includes(:operations, :step_type)}
      scope :finished, ->() { where("state != 'running' AND state IS NOT NULL").includes(:operations, :step_type)}
      scope :in_activity, ->() { where.not(activity_id: nil)}
    end
  end  

  def active?
    ((state == 'running') || (state.nil?))
  end

  def completed?
    (state == 'complete')
  end

  def cancelled?
    (state == 'cancel')
  end

  def failed?
    (state == 'error')
  end

  def running?
    (state == 'running')
  end

end