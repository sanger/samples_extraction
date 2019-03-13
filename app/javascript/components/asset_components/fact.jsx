import React from 'react'
class Fact extends React.Component {

  constructor(props) {
    super(props)
    this.valueForPredicate = this.valueForPredicate.bind(this)
    this.classType = this.classType.bind(this)
    this.renderShortDescription = this.renderShortDescription.bind(this)
    this.renderObject = this.renderObject.bind(this)
  }

  valueForPredicate(asset, predicate) {
    let val = (asset.facts && asset.facts.filter((a) => {
      return (a.predicate == predicate)
    })[0])
    if (val) {
      return val.object
    } else {
      return ''
    }
  }

  classType(asset) {
    return this.valueForPredicate(asset, 'a')
  }

  renderShortDescription(asset) {
    let label = (asset && asset.barcode) ? asset.barcode : '#'+asset.id
    return(`${this.valueForPredicate(asset, 'aliquotType')} ${this.classType(asset)} ${label}`)
  }

  renderObject(fact) {
    if (fact.object_asset_id) {
      let url = `/labware/${fact.object_asset_id}`

      return (
        <a className="object-reference" href={url}>
          { fact.object_asset ? this.renderShortDescription(fact.object_asset) : '#'+fact.object_asset_id }
        </a>
      )
    } else {
      return ( fact.object )
    }
  }

  render() {
    const fact = this.props.fact

    return(
      <div className="fact administrator-allowed">
        <span className={"label "+ (fact["is_remote?"] ? 'label-info' : 'label-default')}>
        <span className="predicate">
          { fact.predicate }
        </span>
        :
        <span className="object">
        </span>
          {this.renderObject(fact)}
        </span>
      </div>
    )
  }
}

export default Fact
