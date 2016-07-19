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

  proto.addFact = function(fact) {
    if ($('.facts .fact', this.node).length===0) {
      this.facts.text('');
    }
    var renderedFact = this.factTemplate(fact);
    if (fact.actionType=='checkFacts') {
      this.checksDiv.append(renderedFact);
    } else {
      this.facts.append(renderedFact);
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
