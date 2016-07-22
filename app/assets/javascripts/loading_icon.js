(function($, undefined) {
  function LoadingIcon(node, params) {
    this.node=$(node);

    this.containerIconClass = params.containerIconClass || "spinner";
    this.iconClass = params.iconClass || "glyphicon";
    this.icon = $('.'+this.iconClass, this.node);
    this.loadingClass = params.loadingClass || "fast-right-spinner"
    this.container = $('.'+this.containerIconClass, this.node);

    $(this.container).hide();

    this.attachHandlers();
  };
  var proto = LoadingIcon.prototype;

  proto.onStartLoad = function(e, data) {
    $(data.node).hide();
    $(this.icon).addClass(this.loadingClass);
    $(this.container).show();
  };

  proto.onStopLoad = function(e, data) {
    $(this.container).hide();
    $(this.icon).removeClass(this.loadingClass);
    $(data.node).show();
  };

  proto.attachHandlers = function() {
    $(this.node).on('load_start.loading_spinner', $.proxy(this.onStartLoad, this));
    $(this.node).on('load_stop.loading_spinner', $.proxy(this.onStopLoad, this));
  };

  $(document).on('ready', function() {
    $(document).trigger('registerComponent.builder', {'LoadingIcon': LoadingIcon});
  });

}(jQuery));
