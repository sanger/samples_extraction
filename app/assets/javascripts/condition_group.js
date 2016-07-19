(function($, undefined) {
  function ConditionGroup(node){
    this.factTemplate = JST['templates/fact'];
    this.node = node;
    this.name = $('h3[psd-condition-group-title]', node).data('psd-condition-group-title');
    this.attachHandlers();
  };

  var proto = ConditionGroup.prototype;

  proto.addFact = function(fact) {
    if ($('.panel-body .fact', this.node).length===0) {
      $('.panel-body', this.node).text('');
    }
    $('.panel-body', this.node).append(this.factTemplate(fact));
  };

  proto.listenFactsHandler = function(event, fact) {
    this.addFact(fact);
    event.preventDefault();
    event.stopPropagation();
  };

  proto.attachHandlers = function() {
    $(this.node).on('fact.fact_reader', $.proxy(this.listenFactsHandler, this));
  };

  $(document).trigger('registerComponent.builder', {'ConditionGroup': ConditionGroup});
}(jQuery));
