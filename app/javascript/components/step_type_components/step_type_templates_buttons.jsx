import React from 'react'
import StepTypeTemplateButton from "./step_type_template_button"

class StepTypeTemplatesButtons extends React.Component {
  render() {
    return(
      this.props.stepTypesTemplatesData.map((stepTypeTemplateData, pos) => {
      	return (<StepTypeTemplateButton stepTypeTemplateData={stepTypeTemplateData} key={pos}
        		      	selectedTubePrinter={this.props.selectedTubePrinter}
				      	selectedPlatePrinter={this.props.selectedPlatePrinter}          	

      	/>)
      })
    )
  }
}

export default StepTypeTemplatesButtons;