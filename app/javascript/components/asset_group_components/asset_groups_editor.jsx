import React from 'react'
import AssetGroupEditor from "../asset_group_components/asset_group_editor"

class AssetGroupsEditor extends React.Component {
  renderTab(assetGroup, index) {
    const selectedClass = (assetGroup.selected === true)? 'active' : ''
    return(
      <li role="presentation" className={ selectedClass } key={ index }>
        <a href="#"
          aria-controls={ assetGroup.condition_group_name } role="tab" >
          { assetGroup.condition_group_name }
        </a>
      </li>
    )
  }
  renderPanel(assetGroup, index) {
    return(
      <div role="tabpanel" className="tab-pane active"
        id="asset-group-container" key={index}>
        <AssetGroupEditor assetGroup={assetGroup}/>
      </div>
    )
  }
  render() {
    return(
      <div>
      {/* Tab panes */}
        <div className="tab-content asset-groups">
            <label className="control-label">What do I have?</label>

          {/* Nav tabs */}
          <ul className="nav nav-tabs" role="tablist">
            {this.props.assetGroups.map(this.renderTab)}
          </ul>

          {this.props.assetGroups.map(this.renderPanel)}
        </div>

      </div>


    )
  }
}

export default AssetGroupsEditor
