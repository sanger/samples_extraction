import React from 'react'

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