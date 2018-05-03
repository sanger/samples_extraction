import React from 'react'

import StepTypes from "./step_types"

class StepTypesActive extends React.Component {
  render() {
    return(
			<div className="form-group step_types_active"
				data-psd-step-types-update-url={ this.props.activeStepTypes.updateUrl }>
			  <label className="control-label">What can I do with it?</label>
			  <div className="panel panel-default">
			    <div className="panel-body" data-psd-component-class="LoadingIcon"
            data-psd-component-parameters='{ "iconClass": "glyphicon", "containerIconClass": "spinner", "loadingClass": "fast-right-spinner"}'>
			      <div className="spinner" style={{display: 'none'}}>
			        <span className="glyphicon glyphicon-refresh"></span> Please, wait while we refresh this content...
			      </div>
			      <div className="content_step_types">
			        <StepTypes
                instanceId={this.props.instanceId}
                stepsRunning={this.props.stepsRunning}
                assetGroupId={this.props.assetGroupId}
                onExecuteStep={this.props.onExecuteStep}
        		      	selectedTubePrinter={this.props.selectedTubePrinter}
				      	selectedPlatePrinter={this.props.selectedPlatePrinter}

			        	stepTypesData={this.props.activeStepTypes.stepTypesData}
			        	stepTypesTemplatesData={this.props.activeStepTypes.stepTypesTemplatesData}
			        />
			      </div>
			    </div>
			  </div>
			</div>
    )

  }
}

export default StepTypesActive;
