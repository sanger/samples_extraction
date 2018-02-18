import React from 'react'

class StepTypesActive extends React.Component {
  render() {
    return(
			<div className="form-group step_types_active" data-psd-step-types-update-url="<%= activity_step_types_path(@activity) %>">
			  <label className="control-label">What can I do with it?</label>
			  <div className="panel panel-default">
			  <!--div className="panel-header">
			    <%#= render :partial => 'user_status_navbar' %>
			  </div -->

			    <div className="panel-body" data-psd-component-className="LoadingIcon" data-psd-component-parameters='{ "iconClass": "glyphicon", "containerIconClass": "spinner", "loadingClass": "fast-right-spinner"}'>
			      <div className="spinner" style="display:none;">
			        <span className="glyphicon glyphicon-refresh"></span> Please, wait while we refresh this content...
			      </div>
			      <div className="content_step_types">
			        <% unless @step_types.nil? || @step_types.empty? %>
			          <%= render :partial => 'step_types/step_type', :locals => {
			            :step_types => @step_types,
			            :activity => @activity} %>
			        <% else %>
			          <div className="empty-description">
			            <span>No actions can be performed with the selected group of assets for this activity type.</span>
			          </div>
			        <% end %>
			      </div>
			    </div>
			  </div>
			</div>

    )

  }
}