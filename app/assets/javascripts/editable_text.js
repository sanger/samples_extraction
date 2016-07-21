(function($, undefined) {
  function EditableText(node) {
    this.node = $(node);
    this.template = JST['templates/editable_text'];
    this.node.addClass('editable-text');
    this.attachHandlers();
  };

  var proto = EditableText.prototype;

  proto.restoreContent = function() {
    //this.contents.html(this.getTextFromEditor());
    if (this.contents===null) {
      return;
    }
    if (this.validatesContent()) {
      $(this.node).html(this.getTextFromEditor());
    } else {
      $(this.node).html(this.contents);
      $(document).trigger('msg.display_error', {msg: 'The supplied text should be composed of alphabetic characters'});
    }

    this.contents=null;
    this.attachEditor();

    $(this.node).trigger('updated-text.editable-text', {text: this.getTextFromEditor(), node: this.node});
  };

  proto.validatesContent = function() {
    var regexp = $(this.node).data('psg-editable-text-regexp');
    if (regexp) {
      return !!(this.getTextFromEditor().match(new RegExp(regexp)));
    }
    return true;
  };

  proto.attachEditor = function() {
    $(this.node).one('click', $.proxy(this.addEditor, this));
  };

  proto.getTextFromEditor = function() {
    return this.editor.val();
  };

  proto.specialKeysHandler = function(e) {
    if (e.keyCode === 9) {
      this.restoreContent();
      e.preventDefault();
    }
    if (e.keyCode == 13) {
      this.restoreContent();
      e.preventDefault();
    }
  };

  proto.setInputFocus = function() {
    $(this.editor).focus();
    this.editor[0].selectionStart = this.editor[0].selectionEnd = this.editor[0].value.length;
  };

  proto.addEditor = function(event) {
    var editorRendered = this.template({text: $(this.node).text()});
    this.contents = $(this.node).contents();
    $(this.node).html(editorRendered);

    this.editor = $('input', this.node);
    this.editor.on('blur', $.proxy(this.restoreContent, this));
    //$(document).one('click', $.proxy(this.restoreContent, this));
    this.editor.on('keydown', $.proxy(this.specialKeysHandler, this));

    this.setInputFocus();

  };

  proto.attachHandlers = function() {
    this.attachEditor();
  };

  $(document).trigger('registerComponent.builder', {'EditableText': EditableText});

}(jQuery));
