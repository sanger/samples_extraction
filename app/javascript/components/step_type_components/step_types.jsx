import React from 'react'

class StepTypes extends React.Component {
	render() {
	  if (this.props.stepTypesData == null) {
	  	return(
		    <div className="empty-description">
		      <span>No actions can be performed with the selected group of assets for this activity type.</span>
		    </div>	  	
	  	)
	  } else {
	  	return(
	  		<ul className="step-selection list-inline ">
	  		  <StepTypeButtons stepTypesData={this.props.stepTypesData}/>
	  		  <StepTypeTemplateButtons stepTypesTemplatesData={this.props.stepTypesTemplatesData} />
	  		</ul>
	  		<StepTypeTemplatesControls stepTypesTemplatesData={this.props.stepTypesTemplatesData} />	  		
	  	)
	  }
	}
}