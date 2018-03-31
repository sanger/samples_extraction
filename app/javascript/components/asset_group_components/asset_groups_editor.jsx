import React from 'react'
import AssetGroupEditor from "../asset_group_components/asset_group_editor"

class AssetGroupsEditor extends React.Component {
  constructor(props) {
    super(props)
    this.renderTab = this.renderTab.bind(this)
    this.renderPanel = this.renderPanel.bind(this)
  }
  renderTab(assetGroup, index) {
    const selectedClass = (assetGroup.selected === true)? 'active' : ''
    return(
      <li
        style={{cursor: 'pointer'}}
        onClick={$.proxy(this.props.onSelectAssetGroup, this, assetGroup)}
        role="presentation" className={ this.classSelection(assetGroup) } key={ index }>
        <a
          onClick={$.proxy(this.onSelectAssetGroup, this, assetGroup)}
          key={ index }
          aria-controls={ assetGroup.condition_group_name } role="tab" >
          { assetGroup.condition_group_name }
        </a>
      </li>
    )
  }
  classSelection(assetGroup) {
    return (this.props.selectedAssetGroup == assetGroup.id)? 'active' : ''
  }
  renderPanel(assetGroup, index) {
    return(
      <div role="tabpanel" className={"tab-pane "+this.classSelection(assetGroup)}
        id={'asset-group-'+assetGroup.id}
        key={index}>
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
