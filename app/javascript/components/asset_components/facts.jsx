import React from 'react'
import Fact from '../asset_components/fact'
class Facts extends React.Component {
  renderFact(fact, index) {
    return(<Fact fact={fact}/>)
  }
  render() {
    return(
      <span className="facts-list ">
        <span>
          <div className='svg '></div>
          <div className="col-xs-10">
            {this.props.facts.map(this.renderFact)}
          </div>
        </span>
      </span>
    )
  }
}
export default Facts
