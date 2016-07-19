  (function() {
    var POS = 0;

    function ConditionGroups(node) {
      this.template = JST['templates/condition_group'];
      this.node = $(node);
      this.factReaders = [];
      this.attachHandlers();
    };

    var proto = ConditionGroups.prototype;

    proto.addGroup = function() {
      var conditionGroup = this.template({
        name: this.generateGroupName(),
        actionTypes: this.node.data('psd-condition-group-action-types')
      });
      $('#conditionGroups').append(conditionGroup);
      $(document).trigger('execute.builder');
    };

    proto.generateGroupName = function() {
      POS = POS + 1;
      return "Asset" + POS;
    };

    proto.attachHandlers = function() {
      $(this.node).on('click', $.proxy(this.addGroup, this));
    };

    $(document).trigger('registerComponent.builder', {'ConditionGroups': ConditionGroups});

  }());

