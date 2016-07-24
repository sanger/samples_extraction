(function($, undefined) {
    function BarcodeReader(node, params) {
	this.node = $(node);
	this.input = $('input', node);
        this.button = $('button', node);

	this.attachHandlers();
    };

    var proto = BarcodeReader.prototype;

  proto.readInput = function(e) {
    if (e.keyCode === 9) {
	this.send();
	this.input.val('');
      e.preventDefault();
    }
    if (e.keyCode == 13) {
	this.send();
	this.input.val('');	
      e.preventDefault();
    }
  };

    
    proto.attachHandlers = function() {
	this.input.on('keydown', $.proxy(this.readInput, this));
	this.button.on('click', $.proxy(this.send, this));	
    };

    proto.send = function() {
	var data = {barcode: this.input.val()};
        $(this.node).trigger('barcode.barcode_reader', data);	

    };

    $(document).on('ready', function() {
	$(document).trigger('registerComponent.builder', {'BarcodeReader': BarcodeReader});
    });
}(jQuery));
