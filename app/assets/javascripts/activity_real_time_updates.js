(function($, undefined) {
  function ActivityRealTimeUpdates(node, params) {
    this.node = $(node);
    this.urlUpdates = params.url;
    this.lastUpdate = "";
    this.attachHandlers();
  }
  var proto = ActivityRealTimeUpdates.prototype;

  proto.getAssetGroupContainer = function() {
    return $("#asset-group-container form");
  };

  proto.onAssetGroupUpdates = function(e) {
    if (e.data > this.lastUpdate) {
      this.getAssetGroupContainer().trigger('submit.rails');
      this.lastUpdate = e.data;
      this.node.html(this.lastUpdate);
    }
  };

  proto.onStepTypeUpdates = function(e) {

  };

  proto.onStepsUpdates = function(e) {

  };  

  proto.onActiveStepUpdates = function(e) {

  };  

  proto.attachHandlers = function() {
    var evtSource = new EventSource(this.urlUpdates, { withCredentials: true });
    evtSource.addEventListener("asset_group", $.proxy(this.onAssetGroupUpdates, this), false);
    evtSource.addEventListener("step_types", $.proxy(this.onStepTypesUpdates, this), false);
    evtSource.addEventListener("steps", $.proxy(this.onStepsUpdates, this), false);
    evtSource.addEventListener("active_step", $.proxy(this.onActiveStepUpdates, this), false);
  };

  $(document).ready(function() {
    $(document).trigger('registerComponent.builder', {'ActivityRealTimeUpdates': ActivityRealTimeUpdates});
  });

}(jQuery));