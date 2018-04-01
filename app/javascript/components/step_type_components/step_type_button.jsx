import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelectionHidden from "../activity_components/printers_selection_hidden"

class StepTypeButton extends React.Component {
  constructor(props) {
    super(props)

    this.onSubmit = this.onSubmit.bind(this)
    this.onAjaxSuccess = this.onAjaxSuccess.bind(this)
  }
  onAjaxSuccess(msg, text) {
    if (msg.errors) {
      msg.errors.forEach(this.props.onErrorMessage)
    } else {
      this.props.onExecuteStep(msg)
    }
  }
  onSubmit(e) {
    e.preventDefault()
    $.ajax({
      method: 'post',
      url: this.props.stepTypeData.createStepUrl,
      success: this.onAjaxSuccess,
      data: $(e.target).serializeArray()
    })
  }
  render() {
		return(
			<li className="btn-group" style={{top: '6px'}}>
		      <FormFor
            onSubmit={this.onSubmit}
            url={this.props.stepTypeData.createStepUrl} className="form-inline activity-desc">
		        <PrintersSelectionHidden
              entityName="step"
		        	selectedTubePrinter={this.props.selectedTubePrinter}
		        	selectedPlatePrinter={this.props.selectedPlatePrinter} />
            <input type="hidden" name="step[step_type_id]" value={this.props.stepTypeData.stepType.id} />
            <input type="hidden" name="step[asset_group_id]" value={this.props.assetGroupId} />

		       	<button type="submit" className='btn btn-primary'>{this.props.stepTypeData.name}</button>
		      </FormFor>
			</li>
		)
  }

}


export default StepTypeButton
