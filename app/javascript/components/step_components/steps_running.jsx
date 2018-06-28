import React from 'react'
import Moment from 'react-moment';
import StepsFinished from '../step_components/steps_finished'


class StepsRunning extends StepsFinished {
  renderDuration(step) {
    if (step.started_at) {
      return(
        <span><Moment unit="seconds" diff={ step.started_at }>{ Date.now() }</Moment>s</span>
      )
    } else {
      return ''
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
          <tr
            data-psd-step-id={ step.id }
            key={"a1-"+index}
            className={this.colorForState(step.state)}>
            <td>{ step.id }</td>
            <td>{ stepTypeName }</td>
            <td>{ stepActivityId }</td>
            <td>{ stepAssetGroup }</td>
            <td>{ stepUsername }</td>
            <td>{ this.renderDuration(step) }</td>
            <td style={{'textAlign': 'center'}}
              className={classForState}>{ this.imageForState(step.state) }</td>
          </tr>
        </React.Fragment>
      )
    }
  }

  render() {
    return(
      <div className="form-group">
        <label className="control-label">What is happening now?</label>
        <div className="panel panel-default">
          <div className="panel-body">
            {this.renderSteps()}
          </div>
        </div>
      </div>
    )
  }
}

export default StepsRunning