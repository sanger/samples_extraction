import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import BarcodeReader from "../asset_group_components/barcode_reader"
import AssetGroup from "../asset_group_components/asset_group"

class AssetGroupEditor extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      barcodesInputText: '',
      disabledBarcodesInput: false
    }
    this.onSubmit = this.onSubmit.bind(this)
    this.onAjaxSuccess = this.onAjaxSuccess.bind(this)
    this.handleBarcodeReaderChange = this.handleBarcodeReaderChange.bind(this)
  }
  componentDidMount() {
    //this.listenSSE()
    this.listenWebSockets()
  }
  listenWebSockets() {
    App.cable.subscriptions.create({channel: 'AssetGroupChannel', asset_group_id: this.props.assetGroup.id }, {
      received: $.proxy(function(data) {
        if (data > this.props.assetGroup.lastUpdate) {
          this.updateAssetGroup()
        }
      }, this)
    })
  }
  onSSEAssetGroupUpdates(e) {
    if (e.data > this.props.assetGroup.lastUpdate) {
      this.updateAssetGroup()
    }
  }

  onAssetsChanging(e) {
    var data = JSON.parse(e.data);
    var state = data.state;
    var uuid = data.uuid;

    $('tr[data-asset-uuid]').each($.proxy(function(pos, tr) {
      if ($(tr).data('asset-uuid') === uuid) {
        if (state === 'running') {
          $(tr).trigger('load_start.loading_spinner');
        }
        if (state === 'hanged') {
          $(tr).trigger('load_stop.loading_spinner');
        }
      }
      if ($(tr).data('asset-uuid') === uuid) {

      } else {

      }
    }, this));
  }

  listenSSE() {
    const evtSource = new EventSource(this.props.assetGroup.updateUrl+'/sse', { withCredentials: true })
    evtSource.addEventListener("asset_group", $.proxy(this.onSSEAssetGroupUpdates, this), false)
    //evtSource.addEventListener("asset_running", $.proxy(this.onAssetsChanging, this), false)
    //evtSource.addEventListener("active_step", $.proxy(this.onActiveStepUpdates, this), false)
  }
  handleBarcodeReaderChange(e) {
    this.setState({barcodesInputText: e.target.value})
  }
  onAjaxSuccess(msg, text) {
    if (msg.errors) {
      msg.errors.forEach(this.props.onErrorMessage)
    } else {
      this.props.onChangeAssetGroup(msg)
    }
    this.setState({disabledBarcodesInput: false, barcodesInputText: ''})
  }
  updateAssetGroup() {
    this.setState({disabledBarcodesInput: true})
    $.ajax({
      method: 'GET',
      url: this.props.assetGroup.updateUrl,
      success: this.onAjaxSuccess
    })
  }
  onSubmit(e) {
    e.preventDefault()
    this.setState({disabledBarcodesInput: true})
    $.ajax({
      method: 'PUT',
      url: this.props.assetGroup.updateUrl,
      success: this.onAjaxSuccess,
      data: $(e.target).serializeArray()
    })
  }
  render() {
    return(
      <div className="form-group" data-psd-component-class="AssetGroup"
         data-psd-component-parameters="{}">
         <FormFor
           url={this.props.assetGroup.updateUrl}
           data-turbolinks="false"
           onSubmit={this.onSubmit}
           className="edit_asset_group">
           <div className="panel panel-default">
             <div className="panel-header barcode-adding-control">
               <BarcodeReader
                 isShown={this.props.isShown}
                 handleChange={this.handleBarcodeReaderChange}
                 barcodesInputText={this.state.barcodesInputText}
                 disabledBarcodesInput={this.state.disabledBarcodesInput}
                 assetGroup={this.props.assetGroup} />
             </div>
             <div className="panel-body collapse in" id="collapseAssets">
               <AssetGroup
                 onRemoveAssetFromAssetGroup={this.props.onRemoveAssetFromAssetGroup}
                 onRemoveAllAssetsFromAssetGroup={this.props.onRemoveAllAssetsFromAssetGroup}
                 assetGroup={this.props.assetGroup} />
             </div>
             <div className="panel-footer">
             </div>
           </div>
         </FormFor>
         {
           /*
           <FormFor url={this.props.assetGroup.updateAssetGroupUrl}
             className="form-inline activity-desc">
             <BarcodeReader />
             <AssetTypeTabs />
             <hr />
            <div class="panel-body collapse in" id="collapseAssets">
              <AssetGroup />
            </div>
            <div class="panel-footer">
            </div>
          </div>

           */
         }
      </div>
    )
  }
}

export default AssetGroupEditor
