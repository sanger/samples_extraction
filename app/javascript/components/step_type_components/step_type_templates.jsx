import React from 'react'

class StepTypeTemplatesButtons extends React.Component {
  render() {
    return(
      this.stepTypeTemplatesData.map((pos,stepTypeTemplateData) => {
      	return (<StepTypeTemplate stepTypeTemplateData={stepTypeTemplateData} />)
      })
    )
  }
}