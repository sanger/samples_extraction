import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelectionHidden from "../activity_components/printers_selection_hidden"

class StepTypeTemplateControl extends React.Component {
	render() {
		const stepTypeTemplateData = this.props.stepTypeTemplateData
		return(
			<div id="{ stepTypeTemplateData.id }" className="tab-pane container step-type-template">
				<div className="container">
				The other step type templates
				</div>

	      <FormFor url={stepTypeTemplateData.createStepUrl} className="form-inline activity-desc">
	        <PrintersSelectionHidden
	        	selectedTubePrinter={this.props.selectedTubePrinter}
	        	selectedPlatePrinter={this.props.selectedPlatePrinter} />
						<input type="hidden" name="step[step_type_id]" value={stepTypeTemplateData.stepType.id} />
            <input type="hidden" name="step[asset_group_id]" value={this.props.assetGroupId} />

				  <input type="button" name="button" style={{display: 'none'}} />
				  <input type="hidden" name='step[state]' value='done' />
	      </FormFor>

			</div>
		)
	}
}

export default StepTypeTemplateControl;
