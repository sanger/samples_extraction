import React from 'react'
import StepsRunning from '../step_components/steps_running'

class StepsFailed extends StepsRunning {
  constructor(props) {
    super(props)
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
          <tr
            data-psd-step-id={ step.id }
            key={"a1-"+index}
            className={this.colorForState(step.state)}>
            <td>{ step.id }</td>
            <td>{ stepTypeName }</td>
            <td>{ step.operations.length }</td>
            <td>{ stepAssetGroup }</td>
            <td>{ stepUsername }</td>
            <td>{ this.renderDuration(step) }</td>
            <td style={{'textAlign': 'center'}}
              className={classForState}><button onClick={this.props.onRetryStep(step)} className="btn btn-success">Retry?</button>&nbsp;<button onClick={this.props.onStopStep(step)} className="btn btn-danger">Stop?</button></td>
          </tr>
        </React.Fragment>
      )
    }
  }
  render() {
    return(
      <div className="form-group">
        <label className="control-label">There are some failed steps...</label>
        <div className="panel panel-default">
          <div className="panel-body">
            {this.renderSteps()}
          </div>
        </div>
      </div>
    )
  }
}

export default StepsFailed
