  (function() {
    var POS = 0;

    function ConditionGroups(node) {
      this.template = JST['templates/condition_group'];
      this.node = $(node);
      this.button = $('[data-psd-condition-group-action-types]', this.node);
      this.factReaders = [];
      this.conditionGroups = [];
      this.attachHandlers();
    };

    var proto = ConditionGroups.prototype;

    proto.addGroup = function() {
      var conditionGroup = this.template({
        name: this.generateGroupName(),
        actionTypes: this.button.data('psd-condition-group-action-types')
      });
      $('#conditionGroups').append(conditionGroup);
      $(document).trigger('execute.builder');
    };

    proto.generateGroupName = function() {
      POS = POS + 1;
      return "Asset" + POS;
    };

    proto.checkFactToN3 = function(group, fact) {
      return "?"+group.getName()+"\t :"+fact.predicate+"\t :"+fact.object+" .\n"
    };

    proto.actionFactToN3 = function(group, fact) {
      return ":step\t :"+fact.actionType+"\t {"+this.checkFactToN3(group, fact)+"} .\n";
    };

    proto.getStepTypeName = function() {
      return $("div.step_type_name input", this.node).val();
    };

    proto.stepTypeToN3 = function() {
      return ":step\t :stepTypeName \"\"\""+this.getStepTypeName()+"\"\"\" .";
    };

    proto.renderRuleN3 = function(n3Checks, n3Actions) {
      return "{"+n3Checks+"} => {"+this.stepTypeToN3() + n3Actions+"} .\n";
    };

    proto.toN3 = function(e) {
      e.preventDefault();
      e.stopPropagation();

      var checksN3 = $.map(this.conditionGroups, $.proxy(function(group) {
        return $.map(group.getCheckFacts(), $.proxy(this.checkFactToN3, this, group));
      }, this)).join('\n');

      var actionsN3 = $.map(this.conditionGroups, $.proxy(function(group) {
        return $.map(group.getActionFacts(), $.proxy(this.actionFactToN3, this, group));
      }, this)).join('\n');

      var n3 = this.renderRuleN3(checksN3, actionsN3);

      $(this.node).trigger('msg.display_error', {msg: n3});

    };

    proto.storeConditionGroup = function(e, data) {
      this.conditionGroups.push(data.conditionGroup);
    };

    proto.updateConditionGroupName = function(e, data) {
      $(this.conditionGroups).each(function(pos, conditionGroup) {
        conditionGroup.updateName(data.nameOld, data.nameNew);
      });
    };

    proto.attachHandlers = function() {
      $(this.button).on('click', $.proxy(this.addGroup, this));
      $(this.node).on('registered.condition-group', $.proxy(this.storeConditionGroup, this));
      $(this.node).on('changed-name.condition-group', $.proxy(this.updateConditionGroupName, this));

      $('[data-psd-condition-groups-save]').on('click', $.proxy(this.toN3, this));
    };

    $(document).trigger('registerComponent.builder', {'ConditionGroups': ConditionGroups});

  }());

