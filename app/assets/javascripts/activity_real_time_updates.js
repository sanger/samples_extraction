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

  proto.onAssetsChanging = function(e) {
    var list = JSON.parse(e.data);

    $('tr[data-asset-uuid]').each($.proxy(function(pos, tr) {
      if (list.indexOf($(tr).data('asset-uuid'))>=0) {
        $(tr).trigger('load_start.loading_spinner');
      } else {
        $(tr).trigger('load_stop.loading_spinner');
      }
    }, this));
  };

  proto.onActiveStepUpdates = function(e) {

  };  

  proto.attachHandlers = function() {
    var evtSource = new EventSource(this.urlUpdates, { withCredentials: true });
    evtSource.addEventListener("asset_group", $.proxy(this.onAssetGroupUpdates, this), false);
    evtSource.addEventListener("asset", $.proxy(this.onAssetsChanging, this), false);
    evtSource.addEventListener("active_step", $.proxy(this.onActiveStepUpdates, this), false);
  };

  $(document).ready(function() {
    $(document).trigger('registerComponent.builder', {'ActivityRealTimeUpdates': ActivityRealTimeUpdates});
  });

}(jQuery));