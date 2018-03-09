import React from 'react'

class BarcodeReader extends React.Component {
  readBarcodes(barcodesStr) {
    return barcodesStr.split(' ').map(function(val) {
      return val.replace(/\"\'/, '');
    });
  }

  readInput(e) {
    if ((e.keyCode === 9) || (e.keyCode == 13)) {
      this.readBarcodes(e)
    }
  }

  onReadBarcodes(e) {
    this.readInput(e)
  }

  render() {
    return(
      <div>
        <label htmlFor="asset_group_add_barcode" className="control-label">Add a barcode</label>
        <div className="input-group">
          <input type="hidden" name="asset_group[delete_barcode]"
            id="asset_group_delete_barcode" value="" />
          <input type="hidden" name="asset_group[delete_all_barcodes]"
            id="asset_group_delete_all_barcodes" value="false" />
          <input name='asset_group[add_barcode]' id="asset_group_add_barcode" className="form-control" type='text' placeholder='Scan a barcode' 
            onKeyDown={this.onReadBarcodes} />
          <span className="input-group-btn">
            <button className="btn btn-default barcode-send" title="Send barcode">
              <span className="glyphicon glyphicon-arrow-down"></span>
            </button>
          </span>
        </div>
      </div>
    )
  }
}

export default BarcodeReader
