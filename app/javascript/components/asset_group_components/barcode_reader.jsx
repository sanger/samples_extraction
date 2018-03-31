import React from 'react'

class BarcodeReader extends React.Component {
  render() {
    return(
      <div data-turbolinks="false">
        <label htmlFor="asset_group_add_barcode" className="control-label">Add a barcode</label>
        <div className="input-group">
          <input value={this.props.barcodesInputText}
            onChange={this.props.handleChange} disabled={this.props.disabledBarcodesInput}
            autoComplete="off" name="asset_group[add_barcodes]"
            className="form-control" type='text' placeholder='Scan a barcode' />
          <span className="input-group-btn">
            <button type="submit" className="btn btn-default barcode-send" title="Send barcode">
              <span className="glyphicon glyphicon-arrow-down"></span>
            </button>
          </span>
        </div>
      </div>
    )
  }
}

export default BarcodeReader
