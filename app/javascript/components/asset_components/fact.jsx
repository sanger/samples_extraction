import React from 'react'
class Fact extends React.Component {
  renderObject(fact) {
    if (fact.object_asset) {
      return (
        <a className="object-reference" href={fact.object_asset.url}>
          { fact.object_asset.short_description }
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
        <span className={"label "+ (fact.is_remote ? 'label-info' : 'label-default')}>
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
