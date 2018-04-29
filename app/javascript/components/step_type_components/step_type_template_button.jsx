import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelectionHidden from "../activity_components/printers_selection_hidden"

class StepTypeTemplateButton extends React.Component {
	render() {
		const stepTypeTemplateData = this.props.stepTypeTemplateData

		return(
	    <li className="btn-group">
	      <a href={ '#' + stepTypeTemplateData.id }
	      	className="btn btn-default" data-toggle="pill">
	      	{stepTypeTemplateData.name}
	      </a>
				<a className="button btn btn-primary hidden">
					Finish
				  <div style={{display: 'none'}} data-psd-component-class-name="FinishStepButton">
				  	<FormFor url={stepTypeTemplateData.createStepUrl} className="form-inline activity-desc">
				   		<PrintersSelectionHidden
								entityName="step"
				    		selectedTubePrinter={this.props.selectedTubePrinter}
				    		selectedPlatePrinter={this.props.selectedPlatePrinter} />
								<input type="hidden" name="step[step_type_id]" value={stepTypeTemplateData.stepType.id} />
		            <input type="hidden" name="step[asset_group_id]" value={this.props.assetGroupId} />

					    <input disabled={this.props.stepsRunning.length > 0} type="hidden" name='step[state]' value='done' />
					  </FormFor>
					</div>
				</a>
	    </li>
		)
	}
}

export default StepTypeTemplateButton;
