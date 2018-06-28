import React from 'react'
import AssetGroupEditor from "../asset_group_components/asset_group_editor"

class AssetGroupsEditor extends React.Component {
  constructor(props) {
    super(props)
    this.renderTab = this.renderTab.bind(this)
    this.renderPanel = this.renderPanel.bind(this)
    this.isShown = this.isShown.bind(this)
    this.classSelection = this.classSelection.bind(this)
  }
  renderTab(assetGroupId, index) {
    const assetGroup = this.props.assetGroups[assetGroupId]
    const selectedClass = (assetGroup.selected === true)? 'active' : ''
    return(
      <li
        style={{cursor: 'pointer'}}
        onClick={$.proxy(this.props.onSelectAssetGroup, this, assetGroup)}
        role="presentation" className={ this.classSelection(assetGroup) }
        key={ assetGroupId }>
        <a
          onClick={$.proxy(this.onSelectAssetGroup, this, assetGroup)}
          key={ assetGroupId }
          aria-controls={ assetGroup.condition_group_name } role="tab" >
          { assetGroup.condition_group_name }
        </a>
      </li>
    )
  }
  classSelection(assetGroup) {
    return this.isShown(assetGroup) ? 'active' : ''
  }
  isShown(assetGroup) {
    return (this.props.selectedAssetGroup == assetGroup.id)
  }
  renderPanel(assetGroupId, index) {
    const assetGroup = this.props.assetGroups[assetGroupId]
    return(
      <div role="tabpanel" className={"tab-pane "+this.classSelection(assetGroup)}
        id={'asset-group-'+assetGroup.id}
        key={'asset-group-'+assetGroup.id}>
        <AssetGroupEditor assetGroup={assetGroup}
          dataRackDisplay={this.props.dataRackDisplay}
          activityRunning={this.props.activityRunning}
          onExecuteStep={this.props.onExecuteStep}
          isShown={this.isShown(assetGroup)}
          onRemoveAssetFromAssetGroup={this.props.onRemoveAssetFromAssetGroup}
          onRemoveAllAssetsFromAssetGroup={this.props.onRemoveAllAssetsFromAssetGroup}
          onErrorMessage={this.props.onErrorMessage}
          onChangeAssetGroup={this.props.onChangeAssetGroup}/>
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
            {Object.keys(this.props.assetGroups).map(this.renderTab)}
          </ul>
          {Object.keys(this.props.assetGroups).map(this.renderPanel)}
        </div>

      </div>


    )
  }
}

export default AssetGroupsEditor
