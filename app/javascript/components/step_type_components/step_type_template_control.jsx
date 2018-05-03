import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelectionHidden from "../activity_components/printers_selection_hidden"
/*import FileCreation from "step_type_templates/file_creation"
import RackLayoutCreatingTubes from "step_type_templates/rack_layout_creating_tubes"
import RackLayout from "step_type_templates/rack_layout"
import RackOrderSymphony from "step_type_templates/rack_order_symphony"
import RackingByColumns from "step_type_templates/racking_by_columns"
import TransferTubeToTube from "step_type_templates/transfer_tube_to_tube"
*/
import UploadFile from "./step_type_templates/upload_file"

class StepTypeTemplateControl extends React.Component {
	renderTemplate(template) {
		ReactDOM.render({
			'file_creation': UploadFile,
			'rack_layout_creating_tubes': UploadFile,
			'rack_layout': UploadFile,
			'rack_order_symphony': UploadFile,
			'racking_by_columns': UploadFile,
			'transfer_tube_to_tube': UploadFile
		}[template])
	}
	render() {
		const stepTypeTemplateData = this.props.stepTypeTemplateData
		return(
			<div id={ stepTypeTemplateData.id + '-' + this.props.instanceId } className="tab-pane container step-type-template">
				<div className="container">
					<UploadFile {...stepTypeTemplateData} />
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
