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
  handleBarcodeReaderChange(e) {
    this.setState({barcodesInputText: e.target.value})
  }
  onAjaxSuccess(msg, text) {
    this.props.onChangeAssetGroup(msg)
    this.setState({disabledBarcodesInput: false, barcodesInputText: ''})
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
                 handleChange={this.handleBarcodeReaderChange}
                 barcodesInputText={this.state.barcodesInputText}
                 disabledBarcodesInput={this.state.disabledBarcodesInput}
                 assetGroup={this.props.assetGroup} />
             </div>
             <div className="panel-body collapse in" id="collapseAssets">
               <AssetGroup assetGroup={this.props.assetGroup} />
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
