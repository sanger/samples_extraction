import React from 'react'

class PrintersSelectionHidden extends React.Component {
  render() {
    return(
    	<HashFields name="activity">
   			<HiddenFieldTag name="tube_printer_id" value={this.props.selectedTubePrinter} className='tube_printer' />
   			<HiddenFieldTag name="plate_printer_id" value={this.props.selectedPlatePrinter} className='plate_printer' />
  		</HashFields>
  	)
  }	
}

export default PrintersSelectionHidden;