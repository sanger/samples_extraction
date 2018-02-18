import React from 'react';
import ReactDOM from 'react-dom';

import ActivityDescription from "./activity_components/activity_description";
import PrintersSelection from "./activity_components/printers_selection";

import {FormFor, HashFields} from "react-rails-form-helpers"

class Activity extends React.Component {
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
	     	platePrinter={this.props.platePrinter} />
     </div>
    );
  }
}

export default Activity
