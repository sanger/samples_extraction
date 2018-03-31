class AssetTypeTabs extends React.Component {
  render() {
    return(
      <% unless @asset_group.assets.empty? %>
      <% @step_types = [] if @step_types.nil? %>
      <div class="panel-body <%= 'not-matched' if @step_types.empty? %>">
        <div>
          <% if @step_types.empty? %>
            <span class="no-compatible-steps-desc">No compatible steps were found. Click through the following list of available steps to check the requirements for each step</span>
          <% end %>
          <div class="row">
            <ul class="nav nav-pills">
            <% @invalid_step_types = @step_types %>
            <% @invalid_step_types = @asset_group.activity.step_types if @step_types.empty? %>
            <% unless @invalid_step_types.length == 1 %>
              <% @invalid_step_types.each do |step_type| %>
                <li role="presentation" class="">
                  <a href="#at-<%= step_type.id %>" aria-controls="at-<%= step_type.id %>" role="tab" data-toggle="tab"><%= step_type.name %></a>
                </li>
              <% end %>
            <% end %>
            </ul>
            <div class="<%= 'tab-content' unless @invalid_step_types.length == 1%>">
              <% @invalid_step_types.each do |step_type| %>
                <div role="tabpanel" class="tab-pane"
                    id="at-<%= step_type.id %>">
                  <% asset_types_for(@assets_grouped, step_type) do |fact_group, assets, cgs| %>
                    <%= render :partial => 'asset_groups/asset_type', :locals => {
                        :fact_group => fact_group, :assets => assets, :cgs => cgs } %>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
      <% end %>
    )
  }
}