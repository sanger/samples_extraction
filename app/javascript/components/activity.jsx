import React from 'react';
import ReactDOM from 'react-dom';

import AlertDisplay from './activity_components/alert_display'
import ActivityDescription from "./activity_components/activity_description"
import PrintersSelection from "./activity_components/printers_selection"
import AssetGroupsEditor from "./asset_group_components/asset_groups_editor"
import StepsFinished from "./step_components/steps_finished"
import StepsRunning from "./step_components/steps_running"
import StepsFailed from "./step_components/steps_failed"
import StepTypesControl from "./step_type_components/step_types_control"


import {FormFor, HashFields} from "react-rails-form-helpers"

const MAX_BARCODE_SIZE = 255

class Activity extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      messages: props.messages,
      selectedTubePrinter: props.tubePrinter.defaultValue,
      selectedPlatePrinter: props.platePrinter.defaultValue,
      selectedAssetGroup: props.activity.selectedAssetGroup,
      stepTypes: props.stepTypes,
      assetGroups: props.assetGroups,
      stepsRunning: props.stepsRunning,
      stepsPending: props.stepsPending,
      stepsFinished: props.stepsFinished,
      stepsFailed: props.stepsFailed,
      activityRunning: props.activityRunning,
      dataAssetDisplay: props.dataAssetDisplay,
      collapsedFacts: {}
    }
    this.onSelectAssetGroup = this.onSelectAssetGroup.bind(this)
    this.onChangeAssetGroup = this.onChangeAssetGroup.bind(this)
    this.onErrorMessage = this.onErrorMessage.bind(this)
    this.onRemoveErrorMessage = this.onRemoveErrorMessage.bind(this)
    this.onRemoveAssetFromAssetGroup = this.onRemoveAssetFromAssetGroup.bind(this)
    this.onRemoveAllAssetsFromAssetGroup = this.onRemoveAllAssetsFromAssetGroup.bind(this)
    this.onExecuteStep = this.onExecuteStep.bind(this)
    this.onChangeStateStep = this.onChangeStateStep.bind(this)
    this.changeStateStep = this.changeStateStep.bind(this)
    this.onStopStep = this.onStopStep.bind(this)
    this.onRetryStep = this.onRetryStep.bind(this)
    this.onCollapseFacts = this.onCollapseFacts.bind(this)
    this.onAddBarcodesToAssetGroup = this.onAddBarcodesToAssetGroup.bind(this)

    this.onToggleStepsFinished = this.onToggleStepsFinished.bind(this)

    this.renderStepTypesControl = this.renderStepTypesControl.bind(this)
  }
  componentDidMount() {
    this.listenWebSockets()
  }
  onCollapseFacts(collapsedFacts, uuid, predicate) {
    return(()=>{
      let obj = Object.create({}, collapsedFacts)
      if (!obj[uuid]) {
        obj[uuid]={}
      }
      if (obj[uuid][predicate] === true) {
        obj[uuid][predicate]=false
      } else {
        obj[uuid][predicate]=true
      }
      return obj
    })
  }
  listenWebSockets() {
    this.activityChannel = App.cable.subscriptions.create({
      channel: 'ActivityChannel',
      activity_id: this.props.activity.id
    }, {
      received: $.proxy(this.onWebSocketsMessage, this)
    })
  }
  onWebSocketsMessage(msg) {
    var selectedGroup = this.state.selectedAssetGroup
    if (!(msg.assetGroups && msg.assetGroups[selectedGroup])) {
      selectedGroup = Object.keys(msg.assetGroups)[0]
    }
    this.setState({
      messages: msg.messages,
      selectedAssetGroup: selectedGroup,
      activityRunning: msg.activityRunning,
      dataAssetDisplay: msg.dataAssetDisplay,
      assetGroups: msg.assetGroups,
      stepTypes: msg.stepTypes,
      stepsRunning: msg.stepsRunning || [],
      stepsFailed: msg.stepsFailed,
      stepsPending: msg.stepsPending || [],
      stepsFinished: msg.stepsFinished
    })
    if (this.awaitingPromises) {
      this.awaitingPromises.forEach((args) => {
        const [resolve, reject] = args
        return resolve(msg)
      })
    }
    this.awaitingPromises = []
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
    return msg
  }
  changeAssetGroup(assetGroup, data) {
    if (!this.awaitingPromises) {
      this.awaitingPromises = []
    }
    let promise = new Promise((resolve, reject) => {
      this.awaitingPromises.push([resolve, reject])
    })


    this.activityChannel.send(data)
    return promise
  }
  getAssetUuidsForAssetGroup(assetGroup) {
    return assetGroup.assets.map((a) => a.uuid)
  }

  barcodesFromInput(barcodes) {
    return barcodes.split(' ').filter((b) => {
      return ((b.length > 0) && (b.length < MAX_BARCODE_SIZE) && (b.match(/\w+/)))
    })
  }
  onAddBarcodesToAssetGroup(assetGroup, userInput) {
    return this.changeAssetGroup(assetGroup,
                                 {asset_group: {
                                   id: assetGroup.id,
                                   assets: this.getAssetUuidsForAssetGroup(assetGroup).concat(this.barcodesFromInput(userInput))
                                 }
                                 }
                                )
  }
  onRemoveAssetFromAssetGroup(assetGroup, asset, pos){
    let uuids = this.getAssetUuidsForAssetGroup(assetGroup)
    uuids.splice(pos, 1)
    return this.changeAssetGroup(assetGroup, {
      asset_group: {
        id: assetGroup.id,
	assets: uuids
      }
    })
  }
  onRemoveAllAssetsFromAssetGroup(assetGroup){
    return this.changeAssetGroup(assetGroup, {
      asset_group: {
        id: assetGroup.id,
	assets: []
      }
    })
  }

  onChangeStateStep(step, toState) {
    return (e) => {
      if ((this.state.activityRunning === true) && (!toState === 'stop')) {
        return;
      }
      const state = toState || (e.target.checked ? 'complete' : 'cancel')
      this.setState({activityRunning: true})
      this.changeStateStep(step, state).then($.proxy(() => { this.setState({activityRunning: false}) }, this))
    }
  }

  changeStateStep(step, state) {
    return $.ajax({
      method: 'PUT',
      dataType: 'json',
      contentType: 'application/json; charset=utf-8',
      url: step.stepUpdateUrl,
      data: JSON.stringify({step: {state}})
    })
  }

  onStopStep(step) {
    return (e) => {
      if (!this.state.activityRunning) {
        return;
      }
      this.changeStateStep(step, 'stop')
    }
  }

  onRetryStep(step) {
    return (e) => {
      if (!this.state.activityRunning) {
        return;
      }
      this.changeStateStep(step, 'retry')
    }
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
  changeShownComponents() {
    this.activityChannel.send({
      activity: {
        id: this.props.activity.id,
        stepsFinished: !this.state.stepsFinished
      }
    })
  }
  onToggleComponentBuilder(componentName) {
    return () => {
      let msg = { activity: {} }
      msg.activity[componentName] = (typeof this.state[componentName] === 'undefined')
      console.log(this.state)
      this.activityChannel.send(msg)
    }
  }
  onToggleStepsFinished() {
    this.changeShownComponents()
  }
  renderStepTypesControl(instanceId) {
    const steps = [].concat(this.state.stepsRunning).concat(this.state.stepsPending)
    if ((this.state.stepsFailed) && (this.state.stepsFailed.length > 0)) {
      return(<StepsFailed
                                       onStopStep={this.onStopStep}
                      onRetryStep={this.onRetryStep}
                      steps={this.state.stepsFailed} />)
    } else {
      if ((this.state.stepsRunning) && (this.state.stepsRunning.length > 0)) {
        return(<StepsRunning steps={this.state.stepsRunning} onStopStep={this.onStopStep} />)
      } else {
  	return(
  	  <StepTypesControl
            onToggle={this.onToggleComponentBuilder('stepTypes')}
            stepTypes={this.state.stepTypes}
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
          dataAssetDisplay={this.state.dataAssetDisplay}
	  activityRunning={this.state.activityRunning}
          onCollapseFacts={this.onCollapseFacts}
          collapsedFacts={null} // {this.state.collapsedFacts}

	  onExecuteStep={this.onExecuteStep}
          onAddBarcodesToAssetGroup={this.onAddBarcodesToAssetGroup}
	  onRemoveAssetFromAssetGroup={this.onRemoveAssetFromAssetGroup}
	  onRemoveAllAssetsFromAssetGroup={this.onRemoveAllAssetsFromAssetGroup}
	  onErrorMessage={this.onErrorMessage}
	  onChangeAssetGroup={this.onChangeAssetGroup}
	  selectedAssetGroup={this.state.selectedAssetGroup}
	  onSelectAssetGroup={this.onSelectAssetGroup}
	  assetGroups={this.state.assetGroups} />
	{this.renderStepTypesControl("2")}
	<StepsFinished
          onToggle={this.onToggleComponentBuilder('stepsFinished')}
          steps={this.state.stepsFinished}
	  activityRunning={this.state.activityRunning}
	  onChangeStateStep={this.onChangeStateStep}/>
      </div>
    )
  }
}

export default Activity
