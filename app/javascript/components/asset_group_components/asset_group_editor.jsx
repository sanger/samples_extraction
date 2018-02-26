import React from 'react'
import {FormFor} from "react-rails-form-helpers"
import BarcodeReader from "../asset_group_components/barcode_reader"
import AssetGroup from "../asset_group_components/asset_group"

class AssetGroupEditor extends React.Component {
  render() {
    return(
      <div className="form-group" data-psd-component-class="AssetGroup"
         data-psd-component-parameters="{}">
         <FormFor url={this.props.assetGroup.updateUrl}
           className="edit_asset_group">
           <div className="panel panel-default">
             <div className="panel-header barcode-adding-control">
               <BarcodeReader />
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
