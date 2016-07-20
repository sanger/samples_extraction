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
    $(this.node).html(this.getTextFromEditor());
    this.attachEditor();
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

  proto.addEditor = function(event) {
    var editorRendered = this.template({text: $(this.node).text()});
    this.contents = $(this.node).contents();
    $(this.node).html(editorRendered);

    this.editor = $('input', this.node);
    this.editor.on('blur', $.proxy(this.restoreContent, this));
    this.editor.on('keydown', $.proxy(this.specialKeysHandler, this));
  };

  proto.attachHandlers = function() {
    this.attachEditor();
  };

  $(document).trigger('registerComponent.builder', {'EditableText': EditableText});

}(jQuery));
