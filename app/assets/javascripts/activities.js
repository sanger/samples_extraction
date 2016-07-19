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
    $('[data-psd-asset-group-delete-barcode]', node).on('click', $.proxy(function(e) {
      if (!((e.screenX==0) && (e.screenY==0))) {
        // Yes, I know...
        $('input[name=delete_barcode]', this.form).val($(e.target).attr('data-psd-asset-group-delete-barcode'));
      }
    }, this));
  };

  proto.cleanInput = function() {
    $('input[name=add_barcode]', this.form).val('');
    $('input[name=delete_barcode]', this.form).val('');
  };

  proto.reloadStepTypes = function() {
    var url = $('#step_types_active').data('psd-step-types-update-url');
    $('#step_types_active').load(url);
  };

  proto.reloadSteps = function() {
    var url = $('#steps_finished').data('psd-steps-update-url');
    $('#steps_finished').load(url);
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
    }, this)).on('ajax:complete', $.proxy(function() {
      if (!this.loadInProgress) {
        this.loadInProgress=true;
        setTimeout($.proxy(function() {
          this.reloadStepTypes();
          this.reloadSteps();
          this.loadInProgress=false;
        }, this), 3000);
      }
    }, this));
  };

  $(document).ready(function() {
    new AssetGroup($('[data-psd-asset-group-form]'));
  });
}(jQuery));
