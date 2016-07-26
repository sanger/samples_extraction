(function($, undefined) {
  function FactSearcher(node, params) {
    this.factSearcherTemplate = JST['templates/fact_searcher'];
    this.factTemplate = JST['templates/fact'];
    this.node = $(node);

    this.node.html(this.factSearcherTemplate());
    this.input = $('input', this.node);
    this.label = $('label', this.node);
    this.content = $('.content', this.label);
    this.cursor = $('span.cursor', this.node);
    this.container = $('div.searcher');

    this.attachHandlers();
  };

  var proto = FactSearcher.prototype;

  proto.onKeyDown = function(e) {
    if ((e.keyCode === 9) || (e.keyCode == 13)) {
      this.input.val(this.input.val()+' ');
    }
    if ((e.keyCode === 9) || (e.keyCode == 13) || (e.keyCode == 32)) {
      this.prepareInput();
    }
    if ((e.keyCode === 9) || (e.keyCode == 13)) {
      e.preventDefault();
    }
    this.resizeInput();
    return true;
  };

  proto.resizeInput = function() {
    if (this.input.val().length>15) {
      $(this.container).css('height', 'auto');
    } else {
      $(this.container).css('height', 'initial');
    }
  };

  proto.prepareInput = function() {
    var value = this.input.val();
    var list = this.joinSemicolon(value.split(/\b/));
    this.input.val($.map(list, function(keyword) {
      if ((keyword.match(/\w/)) && (!keyword.match(/:/))) {
        keyword = 'is:'+keyword;
      }
      return keyword;
    }).join(''));
  };

  proto.concatNodes = function(nodesList) {
    if (nodesList === null) {
      return "";
    }
    if (nodesList.length > 1) {
      var n = $('<div></div>');
      n.append(nodesList)
      return n;
    }
    return nodesList;
  },

  proto.resetHiddenInputs = function() {
    if (typeof this.containerHiddenInputs === 'undefined') {
      this.containerHiddenInputs = $('<div class="hidden"></div>')
      this.node.append(this.containerHiddenInputs);
    }
    this.containerHiddenInputs.html('');
  };

  proto.addHiddenInput = function(name, value) {
    var input = $('<input type="hidden" name="'+name+'" value="'+value+'" ></input>');
    this.containerHiddenInputs.append(input);
  };

  proto.renderKeyword = function(keyword) {
    var list = keyword.split(':');
    if ((list.length >1) && (list[1].length>0)) {
      var predicateLabel= $.parseHTML(list[0]);
      var objectLabel = $.parseHTML(list[1]);
      var predicate = $(predicateLabel).text();
      var object = $(objectLabel).text();

      predicateLabel = this.concatNodes(predicateLabel);
      objectLabel = this.concatNodes(objectLabel);

      return this.factTemplate({
        actionType: '',
        predicate: predicate,
        predicateLabel: $(predicateLabel).html(),
        object:object,
        objectLabel: $(objectLabel).html(),
        cssClasses: ''
      });
    } else {
      keyword= this.replaceEmptySpacesWithHTMLEntity(keyword);
      return keyword;
    }
  };

  proto.replaceEmptySpacesWithHTMLEntity = function(keyword) {
    return keyword.split(/(<[^>]*>)/g).map(function(str) {
      if (str.match(/^\s*$/)) {
        str = str.replace(/\s/g,'<span>&nbsp;</span>');
      }
      return str;
    }).join('');
  };

  proto.joinSemicolon = function(list) {
    var copy = [list[0]];
    for (var i=1; i<list.length; i++) {
      if ((list[i] === ':') || (list[i-1]===':')) {
        copy[copy.length-1] = copy[copy.length-1].concat(list[i]);
      } else {
        copy.push(list[i]);
      }
    }
    return copy;
  };

  proto.createHiddenInputs = function() {
    this.resetHiddenInputs();
    $('.fact', this.node).each($.proxy(function(pos, node) {
      this.addHiddenInput('p'+(pos+1), $(node).data('psd-fact-predicate').replace(/\|/,''));
      this.addHiddenInput('o'+(pos+1), $(node).data('psd-fact-object').replace(/\|/,''));
    }, this));
  };

  proto.renderLabel = function(e) {
    var keywords = this.joinSemicolon(this.input.val().split(/\b/));
    keywords = this.moveCursor(keywords);

    var html = $.map(keywords, $.proxy(this.renderKeyword, this)).join(' ');
    this.content.html(html)
    this.createHiddenInputs();
    $(document).trigger('execute.builder');
    this.reloadCursor();
    return true;
  };


  proto.onFocus = function() {
    this.setInputFocus();
    this.renderLabel();
    this.cursor.show();
    if (typeof this.cursorInterval!== 'undefined') {
      clearInterval(this.cursorInterval);
    }
    this.cursorInterval = setInterval($.proxy(function() {
      this.cursor.hide();
      this.timeout = setTimeout($.proxy(function() {
        this.cursor.show();
      }, this), 325);
    },this),  650);
  };

  proto.getCursorPosition = function(element) {
    var el = $(element).get(0);
    var pos = 0;
    if ('selectionStart' in el) {
        pos = el.selectionStart;
    } else if ('selection' in document) {
        el.focus();
        var Sel = document.selection.createRange();
        var SelLength = document.selection.createRange().text.length;
        Sel.moveStart('character', -el.value.length);
        pos = Sel.text.length - SelLength;
    }
    return pos;
  };

  proto.setInputFocus = function() {
    this.input[0].selectionStart = this.input[0].selectionEnd = this.input[0].value.length;
  };

  proto.onBlur = function() {
    clearTimeout(this.timeout);
    clearInterval(this.cursorInterval);
    this.timeout=null;
    this.cursorInterval = null;
    this.cursor.hide();
  };

  proto.splice = function(str, start, delCount, newSubStr) {
    return str.slice(0, start) + newSubStr + str.slice(start + Math.abs(delCount));
  };

  proto.moveCursor = function(keywords) {
    var absolutePos = this.getCursorPosition(this.input);
    var currentPos = 0;
    var found = false;
    return $.map(keywords, $.proxy(function(keyword) {
      var relativePos = (currentPos+keyword.length) - absolutePos;
      if (!found && (relativePos >= 0)) {
        var p = $('<div><span class="cursor">|</span></div>');
        //p.append(this.cursor);
        keyword = this.splice(keyword, keyword.length - relativePos, 0, p.html());
        this.cursor.remove();
        this.reloadCursor();
        found = true;
      }
      currentPos += keyword.length;
      return keyword;
    }, this));
  };

  proto.reloadCursor = function() {
    this.cursor = $('span.cursor', this.node);
  };

  proto.onKeyPressed = function(e) {
    var keywords = this.input.val().split(' ');
    keywords = this.moveCursor(keywords);
    return true;
  };

  proto.attachHandlers = function() {
    this.input.on('keydown', $.proxy(this.onKeyDown, this));
    this.input.on('keyup', $.proxy(this.renderLabel, this));
    this.input.on('keydown', $.proxy(this.onKeyPressed, this));
    this.input.on('focus', $.proxy(this.onFocus, this));
    this.input.on('blur', $.proxy(this.onBlur, this));
  };

  proto.search = function() {
    $(this.node).trigger('text.fact_searcher', this.input.val());
  };

  $(document).trigger('registerComponent.builder', {'FactSearcher': FactSearcher});

}(jQuery))
