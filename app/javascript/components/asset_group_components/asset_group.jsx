import React from 'react'
import AssetDisplay from "../asset_components/asset_display"
import Facts from '../asset_components/facts'

class AssetGroup extends React.Component {
  renderAssetRow(asset, index) {
    return(
      <tr data-asset-uuid={asset.uuid} data-psd-component-class="LoadingIcon"
        data-psd-component-parameters='{ "iconClass": "glyphicon",
        "containerIconClass": "spinner", "loadingClass":
        "fast-right-spinner"}' key={index}>
        <td>
          <AssetDisplay asset={asset} />
        </td>
        <td data-psd-component-class="AddFactToSearchbox">
          <Facts facts={asset.facts} />
        </td>
        <td>
          <button className="btn btn-primary delete-button">Delete</button>
        </td>
      </tr>
    )
  }
  render() {
    if (this.props.assetGroup.assets.length == 0) {
      return(<div className="empty-description"><span>This activity has no assets selected yet.</span></div>)
    } else {
      return(
        <table className="table table-condensed">
          <thead><tr><th>Barcode</th><th>Facts</th><th>
            <button className="btn btn-primary delete-button" data-psd-asset-group-delete-all-barcodes="">Delete all</button>
          </th></tr></thead>
          <tbody data-psd-asset-group-content="1">
            {this.props.assetGroup.assets.map(this.renderAssetRow)}
          </tbody>
        </table>
      )
    }
  }
}

export default AssetGroup
