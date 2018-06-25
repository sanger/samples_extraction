import React from 'react'
import Operations from '../step_components/operations'
import Toggle from 'react-toggle'



class StepsFinished extends React.Component {
  constructor() {
    super()
    this.colorForState = this.colorForState.bind(this)
    this.classImageForState = this.classImageForState.bind(this)
    this.imageForState = this.imageForState.bind(this)
    this.textColorForState = this.textColorForState.bind(this)
    this.renderStepRow = this.renderStepRow.bind(this)
  }
  colorForState(state) {
    if (state == 'complete') return 'success'
    if (state == 'error') return 'danger'
    if (state == 'running') return 'warning'
    if (state == 'cancel') return 'danger'
    if (state == 'in progress') return 'info'
    return 'primary'
  }
  classImageForState(state) {
    if (state == 'complete') return 'glyphicon-ok'
    if (state == 'error') return 'glyphicon-remove'
    if (state == 'running') return 'glyphicon-refresh fast-right-spinner'
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
              <pre>
                { step.output }
              </pre>
            </td>
          </tr>
          </tbody>
        </table>
      )
    }
  }
  renderStepRow(step,index) {
    const stepTypeName = step.step_type ? step.step_type.name : ''
    const stepActivityId = step.activity ? step.activity.id : ''
    const stepAssetGroup = step.asset_group ? step.asset_group.id : ''
    const stepUsername = step.user ? step.user.username : ''
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
            <td>{ stepActivityId }</td>
            <td>{ stepAssetGroup }</td>
            <td>{ stepUsername }</td>
            <td>{ step.updated_at }</td>
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
                      <Toggle
                        checked={step.state!='cancel'}
                        disabled={this.props.activityRunning}
                        onChange={this.props.onCancelStep(step)}
                        className="pull-right"
                      />
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
          <thead><tr><th>Step id</th><th>Step type</th><th>Activity id</th><th>Asset Group</th><th>Username</th><th>Last update</th><th>Status</th></tr></thead>
          <tbody>
            {this.props.steps.map(this.renderStepRow)}
          </tbody>
        </table>
      )
    }
  }

  render() {
    return(
      <div className="form-group">
        <label className="control-label">What happened before?</label>
        <div className="panel panel-default">
          <div className="panel-body">
            {this.renderSteps()}
          </div>
        </div>
      </div>
    )
  }

}

export default StepsFinished
