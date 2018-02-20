import React from 'react'
import StepTypeTemplateControl from "./step_type_template_control"

class StepTypeTemplatesControls extends React.Component {
	render() {
	  return(
			<div className="step-template-view pull-left">
			  <div className="tab-content">
			  	{this.props.stepTypesTemplatesData.map((stepTypeTemplateData, pos) => {
			  		return(
			  			<StepTypeTemplateControl stepTypeTemplateData={stepTypeTemplateData} 
        		      	selectedTubePrinter={this.props.selectedTubePrinter}
				      	selectedPlatePrinter={this.props.selectedPlatePrinter}          	

			  			/>
			  		)
			  	})}
			  </div>
			</div>

		)
	}
}

export default StepTypeTemplatesControls;