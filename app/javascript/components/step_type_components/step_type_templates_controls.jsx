import React from 'react'
import StepTypeTemplateControl from "./step_type_template_control"

class StepTypeTemplatesControls extends React.Component {
	render() {
	  return(
			<div class="step-template-view pull-left">
			  <div class="tab-content">
			  	{this.stepTypeTemplatesData.map((pos, stepTypeTemplateData) => {
			  		return(
			  			<StepTypeTemplateControl stepTypeTemplateData={stepTypeTemplateData} />
			  		)
			  	})}
			  </div>
			</div>

		)
	}
}

export default StepTypeTemplatesControls;