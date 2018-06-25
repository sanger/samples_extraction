import React from 'react';
import ReactDOM from 'react-dom';

import AlertDisplay from "./activity_components/alert_display"
import ActivityDescription from "./activity_components/activity_description"
import PrintersSelection from "./activity_components/printers_selection"
import AssetGroupsEditor from "./asset_group_components/asset_groups_editor"
import StepsFinished from "./step_components/steps_finished"
import StepsRunning from "./step_components/steps_running"
import StepTypesControl from "./step_type_components/step_types_control"


import {FormFor, HashFields} from "react-rails-form-helpers"

class Activity extends React.Component {
	constructor(props) {
		super(props)
		this.state = {
			selectedTubePrinter: props.tubePrinter.defaultValue,
			selectedPlatePrinter: props.platePrinter.defaultValue,
			selectedAssetGroup: props.activity.selectedAssetGroup,
			stepTypes: props.stepTypes,
			assetGroups: props.assetGroups,
			stepsRunning: props.stepsRunning,
			stepsFinished: props.stepsFinished,	
			activityRunning: props.activityRunning,
			messages: []
		}
		this.onSelectAssetGroup = this.onSelectAssetGroup.bind(this)
		this.onChangeAssetGroup = this.onChangeAssetGroup.bind(this)
		this.onErrorMessage = this.onErrorMessage.bind(this)
		this.onRemoveErrorMessage = this.onRemoveErrorMessage.bind(this)
		this.onRemoveAssetFromAssetGroup = this.onRemoveAssetFromAssetGroup.bind(this)
		this.onRemoveAllAssetsFromAssetGroup = this.onRemoveAllAssetsFromAssetGroup.bind(this)
		this.onExecuteStep = this.onExecuteStep.bind(this)

		this.renderStepTypesControl = this.renderStepTypesControl.bind(this)
	}
	componentDidMount() {
    this.listenWebSockets()
  }
  listenWebSockets() {
    App.cable.subscriptions.create({
			channel: 'ActivityChannel',
			activity_id: this.props.activity.id
		}, {
      received: $.proxy(this.onWebSocketsMessage, this)
    })
  }
	onWebSocketsMessage(msg) {
		this.setState({
			activityRunning: msg.running,
			assetGroups: msg.asset_groups,
			stepTypes: msg.step_types,
			stepsRunning: msg.steps_running || [],
			stepsFinished: msg.steps_finished || this.state.stepsFinished || []
		})
	}
	onRemoveErrorMessage(msg, pos) {
		this.state.messages.splice(pos,1)
		this.setState({messages: this.state.messages})
	}
	onErrorMessage(msg) {
		this.state.messages.push(msg)
		this.setState({messages: this.state.messages})
	}
	onSelectAssetGroup(assetGroup) {
		this.setState({selectedAssetGroup: assetGroup.id})
	}
	onChangeAssetGroup(msg) {
		//this.state.assetGroups[msg.asset_group.id]=msg.asset_group
		//this.state.stepTypes[msg.asset_group.id]=msg.step_types

		//this.setState({
		//	assetGroups: this.state.assetGroups,
		//	stepTypes: this.state.stepTypes
		//})
	}
	changeAssetGroup(assetGroup, data) {
		$.ajax({
      method: 'PUT',
			dataType: 'json',
			contentType: 'application/json; charset=utf-8',
      url: assetGroup.updateUrl,
      success: this.onChangeAssetGroup,
      data: JSON.stringify(data)
    })
	}
	onRemoveAssetFromAssetGroup(assetGroup, asset, pos){
		let assets = this.state.assetGroups[assetGroup.id].assets.slice()
		assets.splice(pos, 1)
		const uuids = assets.map((a) => { return a.uuid })

		this.changeAssetGroup(assetGroup, {
			asset_group: {
				assets: uuids
			}
		})
	}
	onRemoveAllAssetsFromAssetGroup(assetGroup){
		this.changeAssetGroup(assetGroup, {
			asset_group: {
				assets: []
			}
		})
	}

	onChangeTubePrinter() {
		this.setState({selectedTubePrinter: e.target.value})
	}
	onChangePlatePrinter() {
		this.setState({selectedPlatePrinter: e.target.value})
	}
	onExecuteStep(msg) {
		this.setState({activityRunning: true})
	}
	renderStepTypesControl(instanceId) {
		if (this.state.stepsRunning.length > 0) {
			return(<StepsRunning steps={this.state.stepsRunning} />)
		} else {
			return(
				<StepTypesControl stepTypes={this.state.stepTypes}
					instanceId={instanceId}
					onExecuteStep={this.onExecuteStep}
					activityRunning={this.state.activityRunning}
					selectedAssetGroup={this.state.selectedAssetGroup}
					selectedTubePrinter={this.state.selectedTubePrinter}
					selectedPlatePrinter={this.state.selectedPlatePrinter}
					/>
			)			
		}
	}
  render () {
    return (
      <div>
				<AlertDisplay
					onRemoveErrorMessage={this.onRemoveErrorMessage}
					messages={this.state.messages} />
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
				{this.renderStepTypesControl("1")}
			  <AssetGroupsEditor
					onExecuteStep={this.onExecuteStep}
					onRemoveAssetFromAssetGroup={this.onRemoveAssetFromAssetGroup}
					onRemoveAllAssetsFromAssetGroup={this.onRemoveAllAssetsFromAssetGroup}
					onErrorMessage={this.onErrorMessage}
					onChangeAssetGroup={this.onChangeAssetGroup}
					selectedAssetGroup={this.state.selectedAssetGroup}
					onSelectAssetGroup={this.onSelectAssetGroup}
					assetGroups={this.state.assetGroups} />
				{this.renderStepTypesControl("2")}
				<StepsFinished steps={this.state.stepsFinished} />
      </div>
    )
  }
}

export default Activity
