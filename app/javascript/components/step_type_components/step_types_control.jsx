import React from 'react'
import StepTypesActive from "../step_type_components/step_types_active"

class StepTypesControl extends React.Component {
  constructor(props) {
    super(props)
    this.renderStepTypeAssetGroup = this.renderStepTypeAssetGroup.bind(this)
  }
  classForAssetGroup(assetGroupId) {
    return (this.props.selectedAssetGroup == assetGroupId)? '' : 'hidden'
  }
  renderStepTypeAssetGroup(assetGroupId) {
    const stepTypes = this.props.stepTypes[assetGroupId]
    return(
      <div key={assetGroupId} className={this.classForAssetGroup(assetGroupId)}>
        <StepTypesActive
          instanceId={this.props.instanceId}
          key={assetGroupId}
          assetGroupId={assetGroupId}
          activityRunning={this.props.activityRunning}
          onExecuteStep={this.props.onExecuteStep}
          selectedAssetGroup={this.props.selectedAssetGroup}
            activeStepTypes={stepTypes}
            selectedTubePrinter={this.props.selectedTubePrinter}
            selectedPlatePrinter={this.props.selectedPlatePrinter}
        />
      </div>
    )
  }
  render() {
    return Object.keys(this.props.stepTypes).map(this.renderStepTypeAssetGroup)
  }
}

export default StepTypesControl
