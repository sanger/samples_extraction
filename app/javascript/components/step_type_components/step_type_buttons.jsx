import React from 'react'

class StepTypeButtons extends React.Component {
	render() {
		return (this.props.stepTypesData.map((pos,stepTypeData) => {
			return(<StepTypeButton stepTypeData={stepTypeData} />)
		}))
	}
}