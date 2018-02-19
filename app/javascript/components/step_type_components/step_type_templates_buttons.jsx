import React from 'react'
import StepTypeTemplateButton from "./step_type_template_button"

class StepTypeTemplatesButtons extends React.Component {
  render() {
    return(
      this.stepTypeTemplatesData.map((pos,stepTypeTemplateData) => {
      	return (<StepTypeTemplateButton stepTypeTemplateData={stepTypeTemplateData} />)
      })
    )
  }
}

export default StepTypeTemplatesButtons;