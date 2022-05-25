import React from 'react'
import { FormFor } from 'react-rails-form-helpers'

import PrintersSelection from '../activity_components/printers_selection'

/**
  assetGroup: {
    printUrl<String>: The target url for the form
  },
  platePrinter: {
    defaultValue<Numeric>: default printer id,
    optionsData: [
      [
        printer name <String>,
        printer id <Numeric>
      ]
    ]
  },
  tubePrinter: {
    defaultValue<Numeric>: default printer id,
    optionsData: [
      [
        printer name <String>,
        printer id <Numeric>
      ]
    ]
  }
**/
class AssetGroupPrinting extends React.Component {
  constructor(props) {
    super(props)
  }
  render() {
    if (this.props.assetGroup.assets.length > -1) {
      return (
        <FormFor url={this.props.assetGroup.printUrl} className="print_asset_group row">
          <div className="col-xs-10">
            <PrintersSelection tubePrinter={this.props.tubePrinter} platePrinter={this.props.platePrinter} />
          </div>
          <div className="col-xs-2">
            <label className="col-xs-12">&nbsp;</label>
            <button type="submit" className="btn btn-default">
              Print
            </button>
          </div>
        </FormFor>
      )
    } else {
      return '<p>No assets to print</p>'
    }
  }
}

export default AssetGroupPrinting
