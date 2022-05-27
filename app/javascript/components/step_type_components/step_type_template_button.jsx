import React from 'react'

class StepTypeTemplateButton extends React.Component {
  render() {
    const stepTypeTemplateData = this.props.stepTypeTemplateData
    return (
      <li>
        <a
          href={'#' + stepTypeTemplateData.id + '-' + this.props.instanceId}
          className="btn btn-default"
          data-toggle="pill"
        >
          {stepTypeTemplateData.name}
        </a>
      </li>
    )
  }
}

export default StepTypeTemplateButton
