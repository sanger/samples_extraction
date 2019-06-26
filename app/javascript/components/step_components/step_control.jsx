import classNames from 'classnames'
import React from 'react'
import C from '../step_components/step_states'

class StepControl extends React.Component {
  constructor(props) {
    super(props)

    this.buildChangeStateHandler = this.buildChangeStateHandler.bind(this)
    this.renderStepRunningControl = this.renderStepRunningControl.bind(this)
    this.renderStepErrorControl = this.renderStepErrorControl.bind(this)
    this.renderStepFinishedControl = this.renderStepFinishedControl.bind(this)
  }

  buildChangeStateHandler(state) {
    return this.props.onChangeStateStep(this.props.step, state)
  }

  renderStepRunningControl() {
    return(
      <button onClick={this.buildChangeStateHandler(C.STEP_STOPPING)} className="btn btn-danger">Stop?</button>
    )
  }
  renderStepErrorControl() {
    return(
      <React.Fragment>
        <button onClick={this.buildChangeStateHandler(C.STEP_RETRYING)} className="btn btn-success">Retry?</button>&nbsp;
        <button onClick={this.buildChangeStateHandler(C.STEP_STOPPING)} className="btn btn-danger">Stop?</button>
      </React.Fragment>
    )
  }
  renderStepFinishedControl() {
    const state = this.props.step.state

    return(
      <button disabled={this.props.isDisabled}
        onClick={this.buildChangeStateHandler(classNames({
          "`${C.STEP_CONTINUING}`": (state == C.STEP_STOPPED),
          "`${C.STEP_STOPPING}`": (state === null) || (state === C.STEP_FAILED) || (state === C.STEP_RETRY) || (state === C.STEP_RUNNING),
          "`${C.STATE_REMAKING}`": (state === C.STEP_CANCELLED),
          "`${C.STEP_CANCELLING}`": (state === C.STEP_COMPLETED)
        }))}
        className={classNames({
          "pull-right btn": true,
          "btn-danger": (state===C.STEP_COMPLETED) || (state === null) ||
            (state === C.STEP_FAILED) || (state === C.STEP_RETRY) ||(state === C.STEP_RUNNING),
          "btn-primary": (state!=C.STEP_COMPLETED)
          })}>
        {classNames({
          'Stop?': (state === null) || (state === C.STEP_FAILED) || (state === C.STEP_RETRY) || (state === C.STEP_RUNNING),
          'Redo?': (state === C.STEP_CANCELLED),
          'Continue?': (state === C.STEP_STOPPED),
          'Revert?': (state === C.STEP_COMPLETED)
        })}
      </button>
    )
  }
  render() {
    const state = this.props.step.state
    if (!this.props.onChangeStateStep) {
      return null
    }

    switch(state){
      case C.STEP_COMPLETED:
      case C.STEP_STOPPED:
      case C.STEP_CANCELLED:
        return this.renderStepFinishedControl()
      case C.STEP_RUNNING:
        return this.renderStepRunningControl()
      case C.STEP_FAILED:
        return this.renderStepErrorControl()
      default:
        return null
    }
  }
}

export default StepControl
