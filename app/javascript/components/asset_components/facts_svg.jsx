import React from 'react';
import ReactDOM from 'react-dom'
import SVG from 'react-inlinesvg';

class FactsSvg extends React.Component {
  constructor(props) {
    super(props)
    this.numWells = this.numWells.bind(this)
    this.filename = this.filename.bind(this)
    this.pathImage = this.pathImage.bind(this)
    this.nameForFacts = this.nameForFacts.bind(this)
    this.onLoadSvg = this.onLoadSvg.bind(this)
  }
  numWells(facts) {
    return facts.filter((v) => { return v.predicate=='contains'}).length
  }
  filename(facts) {
    const name = this.nameForFacts(facts)
    if (name == 'plate'){
      if (this.numWells(facts) > 96) {
        return '384_plate'
      } else {
        return '96_plate'
      }
    }
    if (name == 'gel') {
      return '96_gel'
    }
    if (name == 'tuberack') {
      return 'tuberack'
    }
    if (name == 'rack') {
      if (this.numWells(facts) <= 24) {
        return '24_rack'
      } else {
        return 'tuberack'
      }
    }
    if (name == 'sampletube') {
      return 'tube'
    }
    if (name == 'tube') {
      return 'tube'
    }
    if (name == 'spincolumn') {
      return 'spin_column'
    }
    if (name == 'filterpaper') {
      return 'filter_paper'
    }
    return null
  }
  nameForFacts(facts) {
    if (facts.length == 0) {
      return null
    }
    let typeFact = facts.find((v) => { return v.predicate=="a" })
    if (!typeFact) {
      return null
    }
    return typeFact.object.toLowerCase()
  }
  pathImage(facts) {
    const img = this.filename(facts)
    if (img) {
      return `/assets/${img}.svg`
    } else {
      return null
    }

  }
  componentDidUpdate() {
    this.onLoadSvg()
  }
  onLoadSvg() {
    var data = this.props.dataRackDisplay[this.props.asset.uuid];
    for (var key in data) {
      var node = $('.svg-'+this.props.asset.uuid+' .'+key);
      node.addClass(data[key].cssClass);
    }
  }

  render() {
    const path = this.pathImage(this.props.facts)
    if (path) {
      return (
        <div className={'svg svg-'+this.props.asset.uuid} >
          <SVG src={this.pathImage(this.props.facts)} ref={el => this.el = el} onLoad={this.onLoadSvg}></SVG>
        </div>
      )
    } else {
      return(
        <div className='svg' style={{fontSize: 'xx-large', float: 'left', marginRight: '0.6em'}}>
          <span className="glyphicon glyphicon-file" />
        </div>
        )      
    }
  }
}

export default FactsSvg
