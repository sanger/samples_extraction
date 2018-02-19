import React from 'react'

class StepTypeTemplate extends React.Component {
	render() {
		return(
	    <li className="btn-group">
	      <a href={ stepTypeTemplateData.href }
	      	className="btn btn-default" data-toggle="pill">
	      	{stepTypeTemplateData.name}
	      </a>
				<a className="button btn btn-primary">
					Finish
				  <div style="display:none;" data-psd-component-className="FinishStepButton">
				  	<FormFor url={this.props.activeStepTypes.createStepUrl} className="form-inline activity-desc">
	       		<PrintersSelectionHidden 
	        		selectedTubePrinter={this.props.selectedTubePrinter}
	        		selectedPlatePrinter={this.props.selectedPlatePrinter} />
				    <input type="hidden" name='step[state]' value='done' />
					</div>
				</a>
	    </li>
		)	
	}
}