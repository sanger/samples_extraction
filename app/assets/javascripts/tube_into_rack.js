(function() {
  function TubeIntoRack(node, params) {
    this.node = $(node);
    this.params = params || {maxColumn: 12, maxRow: 8};
    this.locationPos = 0;
    this.racking = {};

    this.barcodeInput = $('input[name=tube_barcode]', this.node);
    this.attachHandlers();
  };
  var proto = TubeIntoRack.prototype;

  proto.nextLocation = function() {
    this.locationPos += 1;
    return this.locationName(this.locationPos);
  };

  proto.locationName = function(locationPos) {
    var firstCharcode = "A".charCodeAt(0);
    var length = this.params.maxRow;
    var desc_letter = String.fromCharCode(((locationPos-1)%length) + firstCharcode);
    var desc_number = Math.floor((locationPos-1)/length) +1
    return (desc_letter+(desc_number));
  };

  proto.renderTable = function() {
    var list = [];
    for (var key in this.racking) {
      list = list.concat(['<tr class=\"',key,'\""><td>',key, '</td><td>',this.racking[key], '</td></tr>']);
    }
    $('table tbody', this.node).html(list.join(''));
  };

  proto.readBarcode = function(e, data) {
    var cell = this.editNextCell(data.barcode);

    this.renderTable();

  };

  proto.editNextCell = function(barcode) {
    if (this.locationPos >= (this.params.maxColumn * this.params.maxRow)) {
      return;
    }
    var location = this.nextLocation();
    this.racking[location] = barcode;
    var cell = $("."+location);
    if (barcode.length !== 0) {
      //cell.removeClass('empty-edited');
      cell.addClass('edited');
    } /*else {
      cell.addClass('empty-edited');
    }*/
    cell.removeClass('editing');
    var nextCell = $('.'+this.locationName(this.locationPos+1));
    nextCell.addClass('editing');


    cell.off('click');
    cell.on('click', $.proxy(this.modifyCell, this, this.locationPos));


    nextCell.off('click');
    nextCell.on('click', $.proxy(this.modifyCell, this, this.locationPos+1));
    return cell;
  };

  proto.modifyCell = function(locationPos) {
    $('ellipse').removeClass('editing');
    $('table tbody tr').removeClass('info');
    this.locationPos = locationPos - 1;
    var locationName = this.locationName(locationPos);
    this.barcodeInput.val(this.racking[locationName]);
    $('table tbody tr.'+locationName).addClass('info');
    $('.'+this.locationName(locationPos)).addClass('editing');
  };

  proto.attachHandlers = function() {
    this.node.on('barcode.barcode_reader', $.proxy(this.readBarcode, this));
    this.node.on('submit', $.proxy(this.prepareRackContent, this));
  };

  proto.prepareRackContent = function() {
    $('form input[dataParams]', this.node).val(JSON.stringify(this.racking));
  };

  $(document).on('ready', function() {
    $(document).trigger('registerComponent.builder', {'TubeIntoRack': TubeIntoRack});
  });

}(jQuery));
