(function ($, undefined) {
  function RackWellDisplay(node, params) {
    this.node = $(node);
    this.params = params;

    this.attachHandlers();
  };

  var proto = RackWellDisplay.prototype;

  proto.attachHandlers = function() {
    $('svg', this.node).on('click', $.proxy(this.toggleSize, this))
    for (var key in this.params) {
      var node = $('svg .'+key, this.node);
      node.addClass(this.params[key].cssClass);
      node.on('click', $.proxy(this.linkTo, this, this.params[key].url));
    }
  };

  proto.linkTo = function(url) {
    if ($('svg', this.node).hasClass('enlarge')) {
      window.location.href = url;
    }
  };

  proto.toggleSize = function() {
    $('svg', this.node).toggleClass('enlarge');
  };


  $(document).ready(function() {
    $(document).trigger('registerComponent.builder', {'RackWellDisplay': RackWellDisplay});
  });

  }(jQuery));
