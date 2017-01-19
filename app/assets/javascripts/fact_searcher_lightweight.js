(function($, undefined) {
	function FactSearcherLightweight(node, params) {
    this.node = $(node);
		this.params = params;

		this.sidebarTemplate = JST['templates/sidebar_searchbox'];

		this.input = $('#fact_searcher', this.node);
		this.attachHandlers();
	};

	var proto = FactSearcherLightweight.prototype;

	proto.attachHandlers = function() {
		$(this.node).on('submit', $.proxy(this.onSubmit, this));

    $(document).ready(function() {
      $(window).on('resize', function() {
        $('.main-view').height($(window).height()-200);
      });
      $('.main-view').height($(window).height()-200);
    });

	};

	proto.prepareOutput = function() {
		var pos = 0;
		var text = this.input.val();
		text.split(' ').forEach($.proxy(function(param, pos) {
			var list = param.split(':');
			if (list.length == 1) {
	      if (param.match(/^\d\d*$/)) {
	      	list = ['barcode', param];
	      } else {
	      	list = ['is', param];
	      }
			}

			this.addHiddenInput('p'+pos, list[0]);
			this.addHiddenInput('o'+pos, list[1]);
		}, this));
	};

	proto.resetHiddenInputs = function() {
		$('input.for-search', this.node).remove();
	};

	proto.displayInSideBar = function(html) {
		var containerSearchBox = $(this.sidebarTemplate());
    var nodeSearch = $("<div></div>");
    nodeSearch.html(html);
    containerSearchBox.append(nodeSearch);

    containerSearchBox.show();
    containerSearchBox.css('display', 'table-cell');

    $('.main-view').height($(window).height()-200);
    $('.main-view').css('overflow', 'scroll');
    containerSearchBox.css('overflow', 'scroll');
    containerSearchBox.height($(window).height()-200);
    containerSearchBox.on('resize', function() {
      containerSearchBox.height($(window).height()-200);
    });
    containerSearchBox.insertAfter('.main-view');
	};

	proto.search = function() {
		var form = this.node;

    $.get({
      url: form.attr('action'),
      data: form.serialize(),
      success: $.proxy(this.displayInSideBar, this)
    });
	};

	proto.onSubmit = function(e) {
		e.preventDefault();
		this.resetHiddenInputs();
		this.prepareOutput();
		this.search();
	};

  proto.addHiddenInput = function(name, value) {
    var input = $('<input class="for-search" type="hidden" name="'+name+'" value="'+value+'" ></input>');
    this.node.append(input);
  };

  $(document).ready(function() {
    $(document).trigger('registerComponent.builder', {'FactSearcherLightweight': FactSearcherLightweight});
  });


}(jQuery));