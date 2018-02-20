import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelection from "../activity_components/printers_selection"

class StepTypeTemplateControl extends React.Component {
	render() {
		return(
			<div id="{ stepTypeTemplateData.id }" className="tab-pane container step-type-template">
				<div className="container">
				The other step type templates
				</div>

	      <FormFor url={this.props.activeStepTypes.createStepUrl} className="form-inline activity-desc">
	        <PrintersSelectionHidden 
	        	selectedTubePrinter={this.props.selectedTubePrinter}
	        	selectedPlatePrinter={this.props.selectedPlatePrinter} />
				  <input type="button" name="button" style="display:none;"/>
				  <input type="hidden" name='step[state]' value='done' />
	      </FormFor>

			</div>
		)
	}
}

export default StepTypeTemplateControl;