import React from 'react';
import ReactDOM from 'react-dom';

import ActivityDescription from "./activity_components/activity_description"
import PrintersSelection from "./activity_components/printers_selection"
import AssetGroupsEditor from "./asset_group_components/asset_groups_editor"
import StepsFinished from "./step_components/steps_finished"
import StepTypesControl from "./step_type_components/step_types_control"


import {FormFor, HashFields} from "react-rails-form-helpers"

class Activity extends React.Component {
	constructor(props) {
		super()
		this.state = {
			selectedTubePrinter: props.tubePrinter.defaultValue,
			selectedPlatePrinter: props.platePrinter.defaultValue,
			selectedAssetGroup: props.activity.selectedAssetGroup,
			stepTypes: props.stepTypes
		}
		this.onSelectAssetGroup = this.onSelectAssetGroup.bind(this)
	}
	onSelectAssetGroup(assetGroup) {
		this.setState({selectedAssetGroup: assetGroup.id})
	}
	onChangeTubePrinter() {
		this.setState({selectedTubePrinter: e.target.value})
	}
	onChangePlatePrinter() {
		this.setState({selectedPlatePrinter: e.target.value})
	}
  render () {
    return (
      <div>
	      <FormFor url='/edu' className="form-inline activity-desc">
	        <HashFields name="activity">
	          <ActivityDescription	activity={this.props.activity} />
	        </HashFields>
	      </FormFor>
	      <PrintersSelection
	      	selectedTubePrinter={this.state.selectedTubePrinter}
	      	selectedPlatePrinter={this.state.selectedPlatePrinter}
		     	tubePrinter={this.props.tubePrinter}
		     	platePrinter={this.props.platePrinter}
		     	onChangeTubePrinter={this.onChangeTubePrinter}
		     	onChangePlatePrinter={this.onChangePlatePrinter}
		    />
			<StepTypesControl stepTypes={this.state.stepTypes}
				selectedAssetGroup={this.state.selectedAssetGroup}
					selectedTubePrinter={this.state.selectedTubePrinter}
					selectedPlatePrinter={this.state.selectedPlatePrinter}
					/>
			  <AssetGroupsEditor
					selectedAssetGroup={this.state.selectedAssetGroup}
					onSelectAssetGroup={this.onSelectAssetGroup}
					assetGroups={this.props.assetGroups} />
				<StepsFinished steps={this.props.stepsFinished} />
      </div>
    )
  }
}

export default Activity
