import React from 'react'
import StepsFinished from '../step_components/steps_finished'

class Steps extends StepsFinished {
  render() {
    return(
      <StepsFinished steps={this.props.steps} activityRunning={true} onCancelStep={() => {} } />
    )
  }
}

export default Steps
