;(function ($, undefined) {
  function LoadingIcon(node, params) {
    this.node = $(node)

    this.containerIconClass = params.containerIconClass || 'spinner'
    this.iconClass = params.iconClass || 'glyphicon'
    this.icon = $('.' + this.iconClass, this.node)
    this.loadingClass = params.loadingClass || 'fast-right-spinner'
    this.container = $('.' + this.containerIconClass, this.node)
    this.hideNode = $(params.hideNodeSelector)

    $(this.container).hide()

    this.attachHandlers()
  }
  var proto = LoadingIcon.prototype

  proto.onStartLoad = function (e, data) {
    if (data && data.node) {
      $(data.node).hide()
    }
    if (this.hideNode) {
      this.hideNode.hide()
    }
    $(this.icon).addClass(this.loadingClass)
    $(this.container).show()
  }

  proto.onStopLoad = function (e, data) {
    $(this.container).hide()
    $(this.icon).removeClass(this.loadingClass)
    if (data && data.node) {
      $(data.node).show()
    }
    if (this.hideNode) {
      this.hideNode.show()
    }
  }

  proto.attachHandlers = function () {
    $(this.node).on('load_start.loading_spinner', $.proxy(this.onStartLoad, this))
    $(this.node).on('load_stop.loading_spinner', $.proxy(this.onStopLoad, this))
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      LoadingIcon: LoadingIcon,
    })
  })
})(jQuery)
