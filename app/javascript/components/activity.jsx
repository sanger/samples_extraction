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
			stepTypes: props.stepTypes,
			assetGroups: props.assetGroups
		}
		this.onSelectAssetGroup = this.onSelectAssetGroup.bind(this)
		this.onChangeAssetGroup = this.onChangeAssetGroup.bind(this)
	}
	onSelectAssetGroup(assetGroup) {
		this.setState({selectedAssetGroup: assetGroup.id})
	}
	onChangeAssetGroup(msg) {
		this.state.assetGroups[msg.asset_group.id]=msg.asset_group
		this.state.stepTypes[msg.asset_group.id]=msg.step_types

		this.setState({
			assetGroups: this.state.assetGroups,
			stepTypes: this.state.stepTypes
		})
	}
	onChangeTubePrinter() {
		this.setState({selectedTubePrinter: e.target.value})
	}
	onChangePlatePrinter() {
		this.setState({selectedPlatePrinter: e.target.value})
	}
	renderStepTypesControl() {
		return(
			<StepTypesControl stepTypes={this.state.stepTypes}
				selectedAssetGroup={this.state.selectedAssetGroup}
				selectedTubePrinter={this.state.selectedTubePrinter}
				selectedPlatePrinter={this.state.selectedPlatePrinter}
				/>
		)
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
				{this.renderStepTypesControl()}
			  <AssetGroupsEditor
					onChangeAssetGroup={this.onChangeAssetGroup}
					selectedAssetGroup={this.state.selectedAssetGroup}
					onSelectAssetGroup={this.onSelectAssetGroup}
					assetGroups={this.props.assetGroups} />
				{this.renderStepTypesControl()}

				<StepsFinished steps={this.props.stepsFinished} />
      </div>
    )
  }
}

export default Activity
