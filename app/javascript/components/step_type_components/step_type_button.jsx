import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import PrintersSelectionHidden from "../activity_components/printers_selection_hidden"

class StepTypeButton extends React.Component {
  constructor(props) {
    super(props)

    this.onSubmit = this.onSubmit.bind(this)
    this.onAjaxSuccess = this.onAjaxSuccess.bind(this)

    this.state = {
      disabledButton: false
    }
  }
  onAjaxSuccess(msg, text) {
    if (msg.errors) {
      msg.errors.forEach(this.props.onErrorMessage)
    } else {
      this.props.onExecuteStep(msg)
    }
  }
  toggleDisableButton(flag) {
    this.setState({disabledButton: flag})
  }
  onSubmit(e) {
    e.preventDefault()
    this.toggleDisableButton(true)
    $.ajax({
      method: 'post',
      url: this.props.stepTypeData.createStepUrl,
      success: this.onAjaxSuccess,
      data: $(e.target).serializeArray(),
      complete: $.proxy(()=> { this.toggleDisableButton(false) }, this)
    })
  }
  renderButton() {
    const loadingIcon = (<span className="glyphicon glyphicon-refresh fast-right-spinner" aria-hidden="true"></span>)
    return(
      <button disabled={this.state.disabledButton || this.props.activityRunning} type="submit" className='btn btn-primary'>
        {this.props.stepTypeData.name}
        {this.state.disabledButton ? loadingIcon : null }        
      </button>
    )
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
            {this.renderButton()}
		      </FormFor>
			</li>
		)
  }

}


export default StepTypeButton
