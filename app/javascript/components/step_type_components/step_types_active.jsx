import React from 'react'

class StepTypesActive extends React.Component {
  render() {
  return
    return(
			<div className="form-group step_types_active" 
				data-psd-step-types-update-url={ this.props.activeStepTypes.updateUrl }">
			  <label className="control-label">What can I do with it?</label>
			  <div className="panel panel-default">
			    <div className="panel-body" data-psd-component-class="LoadingIcon" data-psd-component-parameters='{ "iconClass": "glyphicon", "containerIconClass": "spinner", "loadingClass": "fast-right-spinner"}'>
			      <div className="spinner" style="display:none;">
			        <span className="glyphicon glyphicon-refresh"></span> Please, wait while we refresh this content...
			      </div>
			      <div className="content_step_types">
			        <StepTypes 
			        	stepTypesData={this.props.activeStepTypes.stepTypesData} 
			        	stepTypeTemplatesData={this.props.activeStepTypes.stepTypeTemplatesData} 
			        />
			      </div>
			    </div>
			  </div>
			</div>

    )

  }
}