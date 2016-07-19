(function($, undefined) {
  function ComponentBuilder() {
    this.instances = [];
    this.components = {};
  };

  var proto = ComponentBuilder.prototype;

  proto.addInstance = function(obj) {
    this.instances.push(obj);
  };

  proto.registerComponent = function(obj) {
    $.extend(this.components, obj);
  };

  proto.instantiateNode = function(node) {
    var className = $(node).data('psd-component-class');
    $(node).removeAttr('data-psd-component-class');
    this.addInstance(new this.components[className](node));
  };

  proto.builderProcess = function() {
    $('[data-psd-component-class]').each($.proxy(function(pos, node) {
      this.instantiateNode(node);
    }, this));
  };

  proto.listenComponentRegistration  = function() {
    $(document).on('registerComponent.builder', $.proxy(function(event, data) {
      this.registerComponent(data);
    }, this));
  };

  proto.listenPageLoad = function() {
    var builderProcess = $.proxy(componentBuilder.builderProcess, componentBuilder);

    // This should be enough but...
    $(document).ready(builderProcess);

    // ... TurboLinks support
    $(document).on('turbolinks:load', builderProcess);

    // ... Jquery mobile support
    $(document).on('pageinit', builderProcess);

    // ... and just in case
    $(document).on('execute.builder', builderProcess);
    //$(document).on('ajax:complete', builderProcess);

  };


  var componentBuilder = new ComponentBuilder();
  componentBuilder.listenPageLoad();
  componentBuilder.listenComponentRegistration();

}(jQuery));
