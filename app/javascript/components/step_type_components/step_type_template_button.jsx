import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelectionHidden from "../activity_components/printers_selection_hidden"

class StepTypeTemplate extends React.Component {
	render() {
		const stepTypeTemplateData = this.props.stepTypeTemplateData

		return(
	    <li className="btn-group">
	      <a href={ '#' + stepTypeTemplateData.id }
	      	className="btn btn-default" data-toggle="pill">
	      	{stepTypeTemplateData.name}
	      </a>
				<a className="button btn btn-primary">
					Finish
				  <div style={{display: 'none'}} data-psd-component-class-name="FinishStepButton">
				  	<FormFor url={stepTypeTemplateData.createStepUrl} className="form-inline activity-desc">
				   		<PrintersSelectionHidden 
				    		selectedTubePrinter={this.props.selectedTubePrinter}
				    		selectedPlatePrinter={this.props.selectedPlatePrinter} />
					    <input type="hidden" name='step[state]' value='done' />
					  </FormFor>
					</div>
				</a>
	    </li>
		)	
	}
}

export default StepTypeTemplate;