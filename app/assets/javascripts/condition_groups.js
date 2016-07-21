  (function() {
    var POS = 0;

    function ConditionGroups(node, params) {
      this.template = JST['templates/condition_group'];
      this.node = $(node);
      this.button = $('[data-psd-condition-group-action-types]', this.node);
      this.buttonNewAsset = $('[data-psd-asset-facts-action-types]', this.node);
      this.conditionGroups = [];
      this.attachHandlers();

      if (params) {
        setTimeout($.proxy(function() {
          this.initializeConditionGroups(params);
        }, this), 0);
      }
    };

    var proto = ConditionGroups.prototype;

    proto.assetFactsTemplate = function() {
      return JST['templates/asset_facts'];
    };

    proto.initializeConditionGroups = function(params) {
      for (var key in params) {
        var template = this.template;
        if (params[key].facts.find(function(f) { return (f.actionType ==="createAsset"); })) {
          template = this.assetFactsTemplate();
        }
        this.addGroup(key, params[key].keepSelected, params[key].facts, template);
      }
    };

    proto.addGroup = function(name, keepSelected, facts, template) {
      var template = template || this.template;
      var conditionGroup = template({
        name: name,
        keepSelected: !!keepSelected,
        actionTypes: this.button.data('psd-condition-group-action-types'),
        facts: JSON.stringify(facts)
      });
      $('#conditionGroups').append(conditionGroup);
      $(document).trigger('execute.builder');
    };

    proto.generateGroupName = function() {
      POS = POS + 1;
      return "Condition" + POS;
    };

    proto.generateAssetName = function() {
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

    proto.renderRuleN3 = function(n3Checks, n3Actions, n3Selects) {
      return "{"+n3Checks+"} => {"+this.stepTypeToN3() + n3Selects + n3Actions+"} .\n";
    };

    proto.toN3 = function(e) {

      var checksN3 = $.map(this.conditionGroups, $.proxy(function(group) {
        return $.map(group.getCheckFacts(), $.proxy(this.checkFactToN3, this, group));
      }, this)).join('\n');

      var actionsN3 = $.map(this.conditionGroups, $.proxy(function(group) {
        return $.map(group.getActionFacts(), $.proxy(this.actionFactToN3, this, group));
      }, this)).join('\n');

      var selectsN3 = $.map(this.conditionGroups, $.proxy(function(group) {
        if (!group.isSelected()) {
          return ":step\t :unselectAsset\t ?" + group.name+".\n";
        } else {
          return "";
        }
      })).join("");

      var n3 = this.renderRuleN3(checksN3, actionsN3, selectsN3);

      $(this.node).trigger('msg.display_error', {msg: n3});

      return n3;
    };

    proto.storeN3 = function(e) {
      $('input#step_type_n3_definition').val(this.toN3());
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
      $(this.button).on('click', $.proxy(function() {
        this.addGroup(this.generateGroupName());
      }, this));
      $(this.buttonNewAsset).on('click', $.proxy(function() {
        this.addGroup(this.generateAssetName(), true, [], this.assetFactsTemplate())
      }, this));
      $(this.node).on('registered.condition-group', $.proxy(this.storeConditionGroup, this));
      $(this.node).on('changed-name.condition-group', $.proxy(this.updateConditionGroupName, this));

      $('[data-psd-condition-groups-save]').on('click', $.proxy(this.storeN3, this));
    };

    $(document).trigger('registerComponent.builder', {'ConditionGroups': ConditionGroups});

  }());

