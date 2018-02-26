import React from 'react'
import StepTypeButtons from "./step_type_buttons"
import StepTypeTemplatesButtons from "./step_type_templates_buttons"
import StepTypeTemplatesControls from "./step_type_templates_controls"


class StepTypes extends React.Component {
	render() {
	  if (this.props.stepTypesData.length == 0) {
	  	return(
		    <div className="empty-description">
		      <span>No actions can be performed with the selected group of assets for this activity type.</span>
		    </div>
	  	)
	  } else {
	  	return(
	  		<div>
		  		<ul className="step-selection list-inline ">
		  		  <StepTypeButtons stepTypesData={this.props.stepTypesData}
        		      	selectedTubePrinter={this.props.selectedTubePrinter}
				      	selectedPlatePrinter={this.props.selectedPlatePrinter}
		  		  />
		  		  <StepTypeTemplatesButtons stepTypesTemplatesData={this.props.stepTypesTemplatesData}
        		      	selectedTubePrinter={this.props.selectedTubePrinter}
				      	selectedPlatePrinter={this.props.selectedPlatePrinter}

		  		  />
		  		</ul>
		  		<StepTypeTemplatesControls stepTypesTemplatesData={this.props.stepTypesTemplatesData}
        		      	selectedTubePrinter={this.props.selectedTubePrinter}
				      	selectedPlatePrinter={this.props.selectedPlatePrinter}

		  		/>
	  		</div>
	  	)
	  }
	}
}

export default StepTypes;
