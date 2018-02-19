import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelection from "../activity_components/printers_selection"

class StepTypeButton extends React.Component {
  render() {
		return(
			<li className="btn-group" style="top:6px;">
		      <FormFor url={this.props.activeStepTypes.createStepUrl} className="form-inline activity-desc">
		        <PrintersSelectionHidden 
		        	selectedTubePrinter={this.props.selectedTubePrinter}
		        	selectedPlatePrinter={this.props.selectedPlatePrinter} />
		       	<button type="submit" className='btn btn-primary'>{this.props.stepTypeData.name}</button>	      	
		      </FormFor>
			</li>
		)
  }
	
}

export default StepTypeButton