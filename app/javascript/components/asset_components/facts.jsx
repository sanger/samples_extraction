import React from 'react'
import Fact from '../asset_components/fact'
import FactsSvg from '../asset_components/facts_svg'

class Facts extends React.Component {
  collapsedPredicate(facts) {
    return facts[0].predicate;
  }
  renderCollapsedControl(facts) {
    let uuid = this.props.asset.uuid
    let pred = this.collapsedPredicate(facts)
    let shown = this.props.collapsedFacts[uuid] && this.props.collapsedFacts[uuid][pred]

    return(      
      <div 
        onClick={this.props.onCollapseFacts(this.props.collapsedFacts, this.props.asset.uuid, this.collapsedPredicate(facts))}
        className="fact administrator-allowed">
          <span className={"label label-warning"}>
          <span className={"glyphicon " + (shown ? 'glyphicon-minus': 'glyphicon-plus')}></span>&nbsp;
          <span className="predicate">
            { this.collapsedPredicate(facts) }
          </span>
          :
          <span className="object">
          </span>
            <span>
              ({facts.length})
            </span>
          </span>
      </div>
    )
  }

  renderCollapsedList(facts) {
    let uuid = this.props.asset.uuid
    let pred = this.collapsedPredicate(facts)
    let shown = this.props.collapsedFacts[uuid] && this.props.collapsedFacts[uuid][pred]
    if (facts.length == 1) {
      return this.renderFact(facts[0])
    } else {
      let render = [this.renderCollapsedControl(facts)]
      if (shown) {
        render = render.concat(facts.map((fact, pos) => { return this.renderFact(fact, pos)}))    
      }
      return(render)
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
