import React from 'react'
import StepTypeButton from "./step_type_button"

class StepTypeButtons extends React.Component {
	render() {
		return (this.props.stepTypesData.map((pos,stepTypeData) => {
			return(<StepTypeButton stepTypeData={stepTypeData} />)
		}))
	}
}

export default StepTypeButtons;