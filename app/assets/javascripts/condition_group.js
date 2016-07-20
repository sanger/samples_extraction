(function($, undefined) {
  function ConditionGroup(node){
    this.factTemplate = JST['templates/fact'];
    this.node = node;
    this.title=$('h3[data-psd-condition-group-title]', node);
    this.checksDiv = $('.check-facts', this.node);
    this.facts = $('.facts', this.node);
    this.name = this.title.data('psd-condition-group-title');
    this.attachHandlers();
  };

  var proto = ConditionGroup.prototype;

  proto.addRenderedFact = function(node, renderedFact) {
    if ($('.fact', node).length===0) {
      node.text('');
    }
    node.append(renderedFact);
  };

  proto.addFact = function(fact) {
    var renderedFact = this.factTemplate(fact);
    if (fact.actionType=='checkFacts') {
      this.addRenderedFact(this.checksDiv, renderedFact);
    } else {
      this.addRenderedFact(this.facts, renderedFact);
    }
    $(document).trigger('execute.builder');
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
