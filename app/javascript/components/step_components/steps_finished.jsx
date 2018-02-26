import React from 'react'
import Steps from '../step_components/steps'

class StepsFinished extends React.Component {
  render() {
    return(
      <div className="form-group">
        <label className="control-label">What happened before?</label>
        <Steps steps={this.props.steps}/>
      </div>
    )
  }
}

export default StepsFinished
