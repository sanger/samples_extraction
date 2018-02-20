import React from 'react'
import StepTypeButton from "./step_type_button"

class StepTypeButtons extends React.Component {
	render() {
		return (this.props.stepTypesData.map((stepTypeData, pos) => {
			return(<StepTypeButton key={'step-type-'+pos} stepTypeData={stepTypeData} 
        		      	selectedTubePrinter={this.props.selectedTubePrinter}
				      	selectedPlatePrinter={this.props.selectedPlatePrinter}          	

			/>)
		}))
	}
}

export default StepTypeButtons;