(function($, undefined) {

  function UploadFile(node, params) {
    this.node = $(node);

    this.form = $('form', this.node);
    this.url = this.form.attr('action');

    this.node.addClass('custom-dropzone');

    this.fileUploadElement = $(".file-upload", this.node);
    this.nextStepElement = $("form", this.node);

    this.buildPreview();
    this.buildDropzone();

    this.attachHandlers();
  };

  var proto = UploadFile.prototype;

  proto.buildPreview = function() {
    // Get the template HTML and remove it from the document template HTML and remove it from the doument
    var previewNode = $('.template', this.node);
    this.previewTemplate = previewNode.html();
    previewNode.remove();
  };

  proto.buildDropzone = function() {
    this.myDropzone = new Dropzone(this.node[0], { // Make the whole body a dropzone
      url: this.url, // Set the url
      method: 'POST',
      paramName: "step[file]",
      thumbnailWidth: 80,
      thumbnailHeight: 80,
      parallelUploads: 20,
      dictDefaultMessage: "Drop a file here and click on 'Upload file'",
      previewTemplate: this.previewTemplate,
      autoQueue: false, // Make sure the files aren't queued until manually added
      previewsContainer: $(".previews", this.node)[0], // Define the container to display the previews
      clickable: $(".fileinput-button", this.node)[0], // Define the element that should be used as click trigger to select files.
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    });
  };

  proto.disableUploadButtons = function(value) {
    if (typeof value === 'undefined') {
      // The event handler for .
      $('.fileinput-button', this.node).toggle(false);
      $('.fileinput-button', this.node).attr('disabled', true);
      $('.start', this.node).attr('disabled', true);
      $('.delete', this.node).attr('disabled', true);
    } else {
      $('.fileinput-button', this.node).toggle(!value);
      $('.fileinput-button', this.node).attr('disabled', value);
      $('.start', this.node).attr('disabled', value);
      $('.delete', this.node).attr('disabled', value);
    }
  }

  proto.alertShow = function(msg) {
    $('.alert .msg', this.node).html(msg);
    $('.alert', this.node).show();
  };

  proto.alertHide = function() {
    $('.alert', this.node).hide();
  };


  proto.onSuccess = function(data, json, xhr) {
    $('.total-progress', this.node).hide();
    //debugger;
    //this.form.submit();
    setTimeout(function() { window.location.reload();}, 1000);
    //this.nextStepElement.submit();
  };

  proto.onAddFile = function(file) {
    this.alertHide();
    // We will reject any intent of adding a file
    // once an uploading process has started:
    if (file.size > (5*1024*1024)) {
      this.alertShow("File "+file.name+" not valid. File size is limited to 5mb. If you need help, please contact the administrators.");
      $('.start', this.node).attr('disabled', true);
      this.myDropzone.removeFile(file);
      return;
    }
    if ($('.fileinput-button', this.node).attr('disabled')==='disabled') {
      this.myDropzone.removeFile(file);
      return;
    }
    // We reject to have more than one file in the sending queue
    this.myDropzone.files.forEach($.proxy(function(storedFile, pos) {
      if (storedFile !== file) {
        this.myDropzone.removeFile(storedFile);
      }
    }, this));
    $(".start", this.node).attr('disabled', false);
    this.singleFileAdded = file;
  };

  proto.onRemoveFile = function(file) {
    this.singleFileAdded = null;
    $(".start", this.node).attr('disabled', true);
  };

  proto.onTotalUploadProgress = function(progress) {
    $('.total-progress .progress-bar', this.node).css('width', progress + "%");
  };

  proto.onSend = function(file, xhr, data) {
    // Show the total progress bar when upload starts
    //data.append('step[state]', 'done')
    $('input', this.form).each($.proxy(function(e, input) {
      data.append($(input).attr('name'), $(input).val());
    }, this));
    $('.total-progress', this.node).show();
  };

  proto.onError = function(file, errorMsg, data) {
    this.alertShow(errorMsg);
    // Show the total progress bar when upload starts
    this.disableUploadButtons(false);
    $('.start', this.node).attr('disabled', true);
    this.myDropzone.removeFile(file);
    this.singleFileAdded = null;
    setTimeout(function() { window.location.reload();}, 1000);
  };

  proto.onQueueComplete = function(progress) {
    // Hide the total progress bar when nothing's uploading anymore
    $('.total-progress', this.node).hide();
  };

  proto.onClickStart = function() {
    this.disableUploadButtons(true);
    this.myDropzone.enqueueFiles(this.myDropzone.getFilesWithStatus(Dropzone.ADDED));
  };

  proto.attachHandlers = function() {
    $('#next', this.node).on('click', function() {
      $('form.new_step').submit();
    });
    this.myDropzone.on("success", $.proxy(this.onSuccess, this));
    this.myDropzone.on("addedfile", $.proxy(this.onAddFile, this));
    this.myDropzone.on("removedfile", $.proxy(this.onRemoveFile, this));
    this.myDropzone.on("totaluploadprogress", $.proxy(this.onTotalUploadProgress, this));
    this.myDropzone.on("sending", $.proxy(this.onSend, this));
    this.myDropzone.on("error", $.proxy(this.onError, this));
    this.myDropzone.on("queuecomplete", $.proxy(this.onQueueComplete, this));
    $(".start", this.node).on('click', $.proxy(this.onClickStart, this));
  };

  $(document).ready(function() {
    $(document).trigger('registerComponent.builder', {'UploadFile': UploadFile});
  });

  /*$(document).ready(function() {
    $('[data-uploader-config]').each(function(pos, node) {
      var config = $(node).data('uploader-config');
      var fileUploader = new ActivityUploadFile(config);
      fileUploader.attachEvents();
    });
  })*/

}(jQuery));
