import React from 'react'

class StepTypeTemplateControl extends React.Component {
	render() {
		return(
			<div id="{ stepTypeTemplateData.id }" class="tab-pane container step-type-template">
				<div class="container">
				 render :partial => 'step_types/step_templates/' + step_type.step_template,
				      :locals => { :step_type => step_type, :index => index } %>
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