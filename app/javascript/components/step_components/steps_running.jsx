import React from 'react'
import Steps from '../step_components/steps'


class StepsRunning extends React.Component {
  render() {
    return(
      <div className="form-group">
        <label className="control-label">What is happening now?</label>
        <div className="panel panel-default">
          <div className="panel-body">
            <Steps steps={this.props.steps}/>
          </div>
        </div>
      </div>
    )
  }
}

export default StepsRunning