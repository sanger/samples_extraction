(function($, undefined) {

  function AssetGroup(node) {
    this.form = node;
    this.identifier = $(node).attr("data-psd-asset-group-form");
    this.content = $('[data-psd-asset-group-content]', node);
    this.template = JST['templates/asset_group'];
    this.attachHandlers(node);
  };

  var proto = AssetGroup.prototype;

  proto.onRemoveBarcode = function(barcode) {

  };

  proto.onAddBarcode = function(barcode) {

  };

  proto.render = function(json) {
    this.content.html(this.template(json));
    this.attachDeleteButtons(this.content);
  };

  proto.attachDeleteButtons = function(node) {
    $('[data-psg-asset-group-delete-barcode]', node).on('click', $.proxy(function(e) {
      if (!((e.screenX==0) && (e.screenY==0))) {
        // Yes, I know...
        $('input[name=delete_barcode]', this.form).val($(e.target).attr('data-psg-asset-group-delete-barcode'));
      }
    }, this));
  };

  proto.cleanInput = function() {
    $('input[name=add_barcode]', this.form).val('');
    $('input[name=delete_barcode]', this.form).val('');
  };

  proto.attachHandlers = function(node) {
    this.attachDeleteButtons(node);

    $(document).on('keydown', 'input[name=add_barcode]', $.proxy(function(e) {
      if (e.keyCode === 9) {
        // Default behaviour of Tabulator is to change to the next input before keyup event; we
        // customized this behaviour to perform a submit Rails-way instead
        this.form.trigger('submit.rails');
        e.preventDefault();
      }
    }, this));

    $(node).on('ajax:success', $.proxy(function(e, json) {
      this.render(json);
      this.cleanInput();
    }, this)).on('ajax:error', $.proxy(function(msg) {
      this.cleanInput();
    }, this));
  };

  $(document).ready(function() {
    new AssetGroup($('[data-psd-asset-group-form]'));
  });
}(jQuery));
