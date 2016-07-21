(function($, undefined) {
  function ButtonSwitch(node) {
    this.node = $(node);
    this.contents = $('[data-psd-button-switch-content]', this.node);
    this.default = $('[data-psd-button-switch-selected]', this.node)[0];

    this.selectedIndex = this.contents.index(this.default);

    this.render();
    this.attachHandlers();
  };

  var proto = ButtonSwitch.prototype;

  proto.render = function() {
    this.node.html(this.selectedContent());
    $(this.node).trigger("value.button_switch", $(this.selectedContent()).data("psd-button-switch-content"));
  };

  proto.switchContent = function() {
    this.selectedIndex += 1;
    if (this.selectedIndex >= this.contents.length) {
      this.selectedIndex=0;
    }
    this.render();
  };

  proto.selectedContent = function() {
    return this.contents[this.selectedIndex];
  };

  proto.attachHandlers = function() {
    $(this.node).on('click', $.proxy(this.switchContent, this));
  };

  $(document).on('ready', function() {
    $(document).trigger('registerComponent.builder', {'ButtonSwitch': ButtonSwitch });
  });
}(jQuery));
