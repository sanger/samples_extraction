import React from 'react'
import Fact from '../asset_components/fact'
import FactsSvg from '../asset_components/facts_svg'

class Facts extends React.Component {

  renderCollapsedList(facts) {
    if (facts.length == 1) {
      return(this.renderFact(facts[0]))
    } else {
      return(
      <div className="fact administrator-allowed">
        <span className={"label label-default"}>
        <span className="predicate">
          { facts[0].predicate }
        </span>
        :
        <span className="object">
        </span>
          <span><span className="glyphicon glyphicon-plus"></span>{facts.length}</span>
        </span>
      </div>
    )      
    }
  }
  renderCollapsedFacts(facts) {
    let rendered = []
    const factsByPredicate = this.factsByPredicate(facts)
    for (var predicate in factsByPredicate) {
      rendered.push(this.renderCollapsedList(factsByPredicate[predicate]))
    }
    return rendered    
  }

  factsByPredicate(facts) {
    return facts.reduce((memo, fact) => {
      if (!memo[fact.predicate]) {
        memo[fact.predicate] = [fact]
      } else {
        memo[fact.predicate].push(fact)
      }
      return memo;
    }, {})
  }

  renderFact(fact, index) {
    return(<Fact fact={fact} key={index} />)
  }
  render() {
    return(
      <span className="facts-list ">
        <span>
          <FactsSvg asset={this.props.asset}  facts={this.props.facts}  dataRackDisplay={this.props.dataRackDisplay}  />
          <div className="col-xs-10">
            {this.renderCollapsedFacts(this.props.facts)}
          </div>
        </span>
      </span>
    )
  }
}
export default Facts
