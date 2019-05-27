import React from 'react';
import ReactDOM from 'react-dom';
import {Label, TextField} from "react-rails-form-helpers"

class ActivityDescription extends React.Component {
	renderCompletedAt() {
		if (this.props.activity.completed_at) {
			return(
				<div className="form-group">
					This activity was finished at {this.props.activity.completed_at}
				</div>
			)
		}
	}
	render() {
  	return(
  		<div>
				{this.renderCompletedAt()}
      	<div className="form-group">
        	<Label htmlFor="activity_type">Activity Type</Label>
        	<TextField className="form-control" name="activity_type" defaultValue={this.props.activity.activity_type_name} readOnly="readonly" />
      	</div>
      	<div className="form-group">
        	<Label htmlFor="instrument">Instrument</Label>
        	<TextField className="form-control" name="instrument" defaultValue={this.props.activity.instrument_name} readOnly="readonly" />
      	</div>

      	<div className="form-group">
        	<Label htmlFor="kit">Kit</Label>
        	<TextField className="form-control" name="kit" defaultValue={this.props.activity.kit_name} readOnly="readonly" />
      	</div>
    	</div>
  	)
	}
}

export default ActivityDescription
