import React from 'react'
import Fact from '../asset_components/fact'
import FactsSvg from '../asset_components/facts_svg'

class Facts extends React.Component {
  renderFact(fact, index) {
    return(<Fact fact={fact} key={index} />)
  }
  render() {
    return(
      <span className="facts-list ">
        <span>
          <FactsSvg facts={this.props.facts} />
          <div className="col-xs-10">
            {this.props.facts.map(this.renderFact)}
          </div>
        </span>
      </span>
    )
  }
}
export default Facts
