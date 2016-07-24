(function($, undefined) {
    function BarcodeReader(node, params) {
	this.node = $(node);
	this.input = $('input', node);

	this.attachHandlers();
    };

    var proto = UserReader.prototype;

  proto.readInput = function(e) {
    if (e.keyCode === 9) {
      this.send();
      e.preventDefault();
    }
    if (e.keyCode == 13) {
      this.send();
      e.preventDefault();
    }
  };

    
    proto.attachHandlers = function() {
	this.input.on('keydown', $.proxy(this.readInput, this));
	this.button.on('keydown', $.proxy(this.send, this));	
    };

    proto.send = function() {
	$(this.node).trigger('barcode.barcode_reader', {barcode: this.input.val()});
	this.input.html('');
    };

    $(document).trigger('registerComponent.builder', {'BarcodeReader': BarcodeReader});    
}(jQuery));
