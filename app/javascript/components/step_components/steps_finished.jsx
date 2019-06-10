import React from 'react'
import Moment from 'react-moment';
import Operations from '../step_components/operations'
import classNames from 'classnames'
import Text from 'react-format-text'
import Toggle from 'react-toggle'


class StepsFinished extends React.Component {
  constructor() {
    super()
    this.colorForState = this.colorForState.bind(this)
    this.classImageForState = this.classImageForState.bind(this)
    this.imageForState = this.imageForState.bind(this)
    this.textColorForState = this.textColorForState.bind(this)
    this.renderStepRow = this.renderStepRow.bind(this)
    this.renderStepControls = this.renderStepControls.bind(this)
  }
  colorForState(state) {
    if (state == 'complete') return 'success'
    if (state == 'error') return 'danger'
    if (state == 'running') return 'warning'
    if (state == 'stop') return 'warning'
    if (state == 'retry') return 'info'
    if (state == 'cancel') return 'danger'
    if (state == 'in progress') return 'info'
    return 'primary'
  }
  classImageForState(state) {
    if (state == 'complete') return 'glyphicon-ok'
    if (state == 'error') return 'glyphicon-remove'
    if (state == 'stop') return 'glyphicon-warning-sign'
    if (state == 'running') return 'glyphicon-refresh fast-right-spinner'
    if (state == 'retry') return 'glyphicon-repeat'
    if (state == 'cancel') return 'glyphicon-erase'
    if (state == 'in progress') return 'glyphicon-repeat'
  }
  imageForState(state) {
    const classToAssign = 'glyphicon ' +
    this.classImageForState(state) + ' ' + this.textColorForState(state)

    return(
      <span className={classToAssign}></span>
    )
  }
  textColorForState(state) {
    return 'text-'+this.colorForState(state)
  }
  renderStepOutput(step) {
    if (step.output) {
      return(
        <table className="table">
          <thead>
            <tr><th>Output</th></tr>
          </thead>
          <tbody>
          <tr className="output">
            <td>
              <Text>
                  { step.output }
              </Text>
            </td>
          </tr>
          </tbody>
        </table>
      )
    }
  }
  renderDuration(step) {
    if (step.started_at && step.finished_at) {
      return(
        <span><Moment unit="seconds" diff={ step.started_at }>{ step.finished_at }</Moment>s</span>
      )
    } else {
      return("")
    }
  }
  renderStepControls(step) {
    if (!this.props.onChangeStateStep) {
      return null
    }
    return(
      <button disabled={this.props.activityRunning && (!step.state ===null)}
        onClick={this.props.onChangeStateStep(step, classNames({
          'stop': (step.state === null) || (step.state === 'error') || (step.state === 'retry') || (step.state === 'running'),
          'complete': (step.state === 'cancel') || (step.state === 'stop'),
          'cancel': (step.state === 'complete')
        }))}
        className={classNames({
          "pull-right btn": true,
          "btn-danger": (step.state==='complete') || (step.state === null) ||
            (step.state === 'error') || (step.state === 'retry') ||(step.state === 'running'),
          "btn-primary": (step.state!='complete')
          })}>
        {classNames({
          'Stop?': (step.state === null) || (step.state === 'error') || (step.state === 'retry') || (step.state === 'running'),
          'Redo?': (step.state === 'cancel'),
          'Continue?': (step.state === 'stop'),
          'Revert?': (step.state === 'complete')
        })}
      </button>
    )
  }
  renderStepRow(step,index) {
    const stepTypeName = step.step_type ? step.step_type.name : ''
    const stepActivityId = step.activity ? step.activity.id : ''
    const stepAssetGroup = step.asset_group ? step.asset_group.id : ''
    const stepUsername = step.username
    const classForState = (step.state == 'running') ? 'spinner' : ''

    const dataTarget = "#step-"+ step.id
    if (step.deprecated == true) {
      return
    } else {
      return(
        <React.Fragment key={index}>
          <tr data-toggle="collapse"
            data-target={dataTarget}
            data-psd-step-id={ step.id }
            key={"a1-"+index}
            className={"clickable  "+ this.colorForState(step.state)}>
            <td>{ step.id }</td>
            <td>{ stepTypeName }</td>
            <td>{ step.operations.length }</td>
            <td>{ stepAssetGroup }</td>
            <td>{ stepUsername }</td>
            <td>{ this.renderDuration(step) }</td>
            <td style={{'textAlign': 'center'}}
              className={classForState}>{ this.imageForState(step.state) }</td>
          </tr>
          <tr key={"a2"+index}
            className="operations ">
            <td colSpan="7">
              <div id={"step-"+ step.id } className="collapse">
                <table className="table">
                  <thead>
                    <tr><th>Action</th><th>Barcode</th>
                    <th>Fact
                      { this.renderStepControls(step) }
                    </th></tr>
                  </thead>
                  <tbody>
                    <Operations operations={step.operations} />
                  </tbody>
                </table>
                {this.renderStepOutput(step)}
              </div>
            </td>
          </tr>
        </React.Fragment>
      )
    }
  }
  renderHeaders() {
    return(<thead>
            <tr><th>Step id</th><th>Step type</th><th>Num. operations</th>
            <th>Asset Group</th><th>Username</th><th>Duration</th><th>Status</th></tr>
          </thead>)
  }
  renderSteps() {
    if (this.props.steps.length == 0) {
      return(
        <div className="empty-description">
          <span>This activity has no steps yet.</span>
        </div>
      )
    } else {
      return(
        <table className="table table-condensed table-hover steps-table">
          { this.renderHeaders() }
          <tbody>
            {this.props.steps.map(this.renderStepRow)}
          </tbody>
        </table>
      )
    }
  }
  render() {
    return this.renderSteps()
  }
}

export default StepsFinished
