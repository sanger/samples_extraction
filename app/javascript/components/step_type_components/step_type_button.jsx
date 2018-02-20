import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelectionHidden from "../activity_components/printers_selection_hidden"

class StepTypeButton extends React.Component {
  render() {
		return(
			<li className="btn-group" style={{top: '6px'}}>
		      <FormFor url={this.props.stepTypeData.createStepUrl} className="form-inline activity-desc">
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