import React from 'react';
import ReactDOM from 'react-dom';

import ActivityDescription from "./activity_components/activity_description"
import PrintersSelection from "./activity_components/printers_selection"
import StepTypesActive from "./step_type_components/step_types_active"

import {FormFor, HashFields} from "react-rails-form-helpers"

class Activity extends React.Component {
	getInitialState() {
		return { 
			selectedTubePrinter: this.props.tubePrinter.defaultValue,
			selectedPlatePrinter: this.props.platePrinter.defaultValue
		}
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
	         <ActivityDescription 
	         	activity_type_name={this.props.activity_type_name} 
	         	kit_name={this.props.kit_name}
	         	instrument_name={this.props.instrument_name}
	         />
	      	</HashFields>
	      </FormFor>
	      <PrintersSelection          	
		     	tubePrinter={this.props.tubePrinter}
		     	platePrinter={this.props.platePrinter} 
		     	onChangeTubePrinter={this.onChangeTubePrinter}
		     	onChangePlatePrinter={this.onChangePlatePrinter}
		    />
		    <StepTypesActive />
      </div>
    )
  }
}

export default Activity
