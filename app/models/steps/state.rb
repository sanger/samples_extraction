module Steps::State
  EVENT_RUN = 'run'
  EVENT_CONTINUE = 'continue'
  EVENT_STOP = 'stop'
  EVENT_REMAKE = 'remake'
  EVENT_CANCEL = 'cancel'


  def self.included(klass)
    klass.instance_eval do
      scope :in_progress, ->() { where(:in_progress? => true)}
      scope :cancelled, ->() {where(:state => 'cancelled')}
      scope :deprecated, ->() {where(:state => 'ignored')}
      scope :processing, ->() {
        where("state = 'running' OR state = 'cancelling' OR  state = 'remaking' OR state = 'retrying'").includes(:operations, :step_type)
      }
      scope :running, ->() { where(state: 'running').includes(:operations, :step_type)}
      scope :pending, ->() { where(state: 'pending')}
      scope :failed, ->() { where(state: 'failed')}
      scope :completed, ->() { where(state: 'complete')}
      scope :stopped, ->() { where(state: 'stopped')}
      scope :active, ->() { where("state = 'running' OR state = 'failed' OR state = 'pending' OR state = 'stopped' OR state IS NULL") }
      scope :finished, ->() { includes(:operations, :step_type)}
      scope :in_activity, ->() { where.not(activity_id: nil)}


      include AASM


      aasm column: :state do
        state :pending, initial: true

        state :cancelled, after_enter: :wss_event
        state :complete, after_enter: :wss_event
        state :running, after_enter: [
          :assets_compatible_with_step_type, :deprecate_unused_previous_steps!, :set_start_timestamp!, :create_job, :wss_event
        ]
        state :cancelling, after_enter: :wss_event
        state :remaking, after_enter: :wss_event
        state :failed, after_enter: :wss_event
        state :ignored
        state :stopped

        event :complete do
          transitions from: :cancelled, to: :complete
          transitions from: [:running,:remaking], to: :complete, after: [
            :clear_job, :set_complete_timestamp!
          ]
        end

        event :cancelled do
          transitions from: [:cancelling,:complete], to: :cancelled
        end

        event :run do
          transitions from: [:pending, :failed, :stopped], to: :running
        end

        event :fail do
          transitions from: [:running, :failed, :stopped], to: :failed, after: [:cancel_me, :save_error_output]
        end

        event :cancel do
          transitions from: [:complete, :cancelling], to: :cancelling,
            after: :cancel_me_and_any_newer_completed_steps
        end

        event :remake do
          transitions from: [:cancelled, :remaking], to: :remaking,
            after: :remake_me_and_any_older_cancelled_steps
        end

        event :continue do
          transitions from: :running, to: :running
          transitions from: [:failed,:stopped], to: :running, after: [:continue_newer_steps, :run]
        end

        event :stop do
          transitions from: :stopped, to: :stopped, after: [:stop_newer_steps]
          transitions from: :cancelled, to: :stopped, after: [:stop_newer_steps]
          transitions from: :pending, to: :stopped, after: [:stop_newer_steps]
          transitions from: :complete, to: :complete, after: [:stop_newer_steps]

          transitions from: :remaking, to: :cancelled, after: [:stop_job, :stop_newer_steps]
          transitions from: [:failed, :running], to: :stopped,
            after: [:stop_job, :stop_newer_steps, :cancel_me]
          transitions from: :cancelling, to: :complete, after: [:stop_job, :stop_newer_steps]
        end

        event :deprecate do
          transitions from: [:failed, :cancelled, :stopped, :pending], to: :ignored, after: :remove_from_activity
        end
      end
    end
  end

  def set_start_timestamp!
    update_columns(started_at: Time.now.utc) if started_at.nil?
  end

  def set_complete_timestamp!
    update_columns(finished_at: Time.now.utc) if finished_at.nil?
  end

  def processing?
    is_processing_state?(state)
  end

  def is_processing_state?(state)
    return false if state.nil?
    running? || cancelling? || remaking?
  end

  def active?
    running? || pending?
    #((self.state == 'running') || (self.state.nil?))
  end

  def completed?
    complete?
  end

end
