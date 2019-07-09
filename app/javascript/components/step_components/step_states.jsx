const C = {
  STEP_STATE_RUNNING: 'running',
  STEP_STATE_IN_PROGRESS: 'in_progress',
  STEP_STATE_CONTINUING: 'continuing',
  STEP_STATE_REMAKING: 'remaking',
  STEP_STATE_CANCELLING: 'cancelling',
  STEP_STATE_FAILED: 'error',
  STEP_STATE_PENDING: 'pending',
  STEP_STATE_CANCELLED: 'cancelled',
  STEP_STATE_COMPLETED: 'complete',

  STEP_EVENT_CONTINUE: 'continue',
  STEP_EVENT_STOP: 'stop',
  STEP_EVENT_REMAKE: 'remake',
  STEP_EVENT_CANCEL: 'cancel'
}

export default C
