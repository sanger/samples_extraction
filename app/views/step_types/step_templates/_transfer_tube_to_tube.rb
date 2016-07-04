
<%= bootstrap_form_for @activity, action: 'update', :html => { :autocomplete => 'off'} do |f| %>
  <label for="asset_barcode[0]" class="control-label">Scan a source</label>
  <div class="input-group">
    <input name='asset_barcode[0]' class="form-control" type='text' placeholder='Scan a barcode' />
  </div>

  <label for="asset_barcode[0]" class="control-label">Scan a destination</label>
  <div class="input-group">
    <input name='asset_barcode[0]' class="form-control" type='text' placeholder='Scan a barcode' />
  </div>
  <%= button_tag(type: 'submit', class: "btn btn-default") do %>
  Transfer
  <% end %>
<% end %>
