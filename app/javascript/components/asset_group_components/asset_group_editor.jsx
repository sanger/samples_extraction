import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import BarcodeReader from "../asset_group_components/barcode_reader"
import AssetGroup from "../asset_group_components/asset_group"
import FineUploaderTraditional from 'fine-uploader-wrappers'
import Dropzone from 'react-fine-uploader/dropzone'
import 'react-fine-uploader/gallery/gallery.css'

function uploaderOptions(props) {
  return(
    {
      options: {
        chunking: {
            enabled: true
        },
        deleteFile: {
            enabled: true,
            endpoint: '/asset_groups/'+props.assetGroup.id+'/upload'
        },
        request: {
            endpoint: '/asset_groups/'+props.assetGroup.id+'/upload',
            customHeaders: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') }
        },
        retry: {
            enableAuto: true
        }
      }
    }
  )
}


class AssetGroupEditor extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      barcodesInputText: '',
      disabledBarcodesInput: false,
      assets_status: {}
    }
    this.onSubmit = this.onSubmit.bind(this)
    this.onAjaxSuccess = this.onAjaxSuccess.bind(this)
    this.onAjaxComplete = this.onAjaxComplete.bind(this)
    this.handleBarcodeReaderChange = this.handleBarcodeReaderChange.bind(this)
    this.assetsChanging = this.assetsChanging.bind(this)
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

  }
  onAjaxComplete() {
    this.setState({disabledBarcodesInput: false, barcodesInputText: ''})
  }
  onSubmit(e) {
    e.preventDefault()
    this.setState({disabledBarcodesInput: true})
    return this.props
      .onAddBarcodesToAssetGroup(this.props.assetGroup, this.state.barcodesInputText)
      //.then(this.onAjaxSuccess)
      .finally(this.onAjaxComplete)
  }
  assetsChanging() {
    return Object.keys(this.state.assets_status).filter($.proxy(function(uuid) {
      return (this.state.assets_status[uuid] == 'running')
    }, this))
  }
  render() {
    return(
      <Dropzone uploader={ new FineUploaderTraditional(uploaderOptions(this.props)) }>
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
                   activityRunning={this.props.activityRunning}
                   isShown={this.props.isShown}
                   onAddBarcodesToAssetGroup={this.props.onAddBarcodesToAssetGroup}
                   handleChange={this.handleBarcodeReaderChange}
                   barcodesInputText={this.state.barcodesInputText}
                   disabledBarcodesInput={this.state.disabledBarcodesInput}
                   assetGroup={this.props.assetGroup} />
               </div>
               <div className="panel-body collapse in" id="collapseAssets">
                 <AssetGroup
                   dataAssetDisplay={this.props.dataAssetDisplay}
                   activityRunning={this.props.activityRunning}
                   onCollapseFacts={this.props.onCollapseFacts}
                   collapsedFacts={this.props.collapsedFacts}

                   onRemoveAssetFromAssetGroup={this.props.onRemoveAssetFromAssetGroup}
                   onRemoveAllAssetsFromAssetGroup={this.props.onRemoveAllAssetsFromAssetGroup}
                   assetGroup={this.props.assetGroup} />
               </div>
               <div className="panel-footer">
               </div>
             </div>
           </FormFor>
        </div>
      </Dropzone>
    )
  }
}

export default AssetGroupEditor
