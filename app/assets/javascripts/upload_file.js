(function() {

  function ActivityUploadFile(obj) {
    this.url = obj.url;
    this.identifier = obj.identifier;
    this.node = $("#"+this.identifier);
    this.node.addClass('dropzone');

    this.fileUploadElement = $(".file-upload", this.node);
    this.nextStepElement = $("form", this.node);
    // Get the template HTML and remove it from the doumenthe template HTML and remove it from the doument
    var previewNode = document.querySelector("#"+this.identifier+" .template");
    previewNode.id = "";
    var previewTemplate = previewNode.parentNode.innerHTML;
    previewNode.parentNode.removeChild(previewNode);

    this.myDropzone = new Dropzone(this.node[0], { // Make the whole body a dropzone
      url: this.url, // Set the url
      method: 'PUT',
      thumbnailWidth: 80,
      thumbnailHeight: 80,
      parallelUploads: 20,
      dictDefaultMessage: "Drop a file here and click on 'Upload file'",
      previewTemplate: previewTemplate,
      autoQueue: false, // Make sure the files aren't queued until manually added
      previewsContainer: "#"+this.identifier+" .previews", // Define the container to display the previews
      clickable: "#"+this.identifier+" .fileinput-button", // Define the element that should be used as click trigger to select files.
      headers: {
            'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    });
  };

  ActivityUploadFile.prototype.disableUploadButtons = function(value) {
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

  ActivityUploadFile.prototype.alertShow = function(msg) {
    $('.alert .msg', this.node).html(msg);
    $('.alert', this.node).show();
  };

  ActivityUploadFile.prototype.alertHide = function() {
    $('.alert', this.node).hide();
  };


  ActivityUploadFile.prototype.attachEvents = function() {
    var myDropzone = this.myDropzone;
    var obj = this;
    myDropzone.on("success", function() {
      $('.total-progress', obj.node).hide();
      obj.nextStepElement.submit();
    });

    myDropzone.on("addedfile", function(file) {
      obj.alertHide();
      // We will reject any intent of adding a file
      // once an uploading process has started:
      if (file.size > (5*1024*1024)) {
        obj.alertShow("File "+file.name+" not valid. File size is limited to 5mb. If you need help, please contact the administrators.");
        $('.start', this.node).attr('disabled', true);
        myDropzone.removeFile(file);
        return;
      }
      if ($('.fileinput-button', obj.node).attr('disabled')==='disabled') {
        myDropzone.removeFile(file);
        return;
      }
      // We reject to have more than one file in the sending queue
      myDropzone.files.forEach(function(storedFile, pos) {
        if (storedFile !== file) {
          myDropzone.removeFile(storedFile);
        }
      });
      $(".start", obj.node).attr('disabled', false);
      obj.singleFileAdded = file;
    });

    myDropzone.on("removedfile", function(file) {
      obj.singleFileAdded = null;
      $(".start", obj.node).attr('disabled', true);
    });


    // Update the total progress bar
    myDropzone.on("totaluploadprogress", function(progress) {
      $('.total-progress .progress-bar', obj.node).css('width', progress + "%");
    });

    myDropzone.on("sending", function(file, xhr, data) {
      // Show the total progress bar when upload starts
      $('.total-progress', obj.node).show();
    });

    myDropzone.on("error", function(file, xhr, data) {
      // Show the total progress bar when upload starts
      obj.disableUploadButtons(false);
      $('.start', this.node).attr('disabled', true);
      myDropzone.removeFile(file);
      obj.singleFileAdded = null;
    });

    // Hide the total progress bar when nothing's uploading anymore
    myDropzone.on("queuecomplete", function(progress) {
      $('.total-progress', obj.node).hide();
    });

    $(".start", obj.node).on('click', function() {
      obj.disableUploadButtons(true);
      myDropzone.enqueueFiles(myDropzone.getFilesWithStatus(Dropzone.ADDED));
    });

  };


  $(document).ready(function() {
    $('[data-uploader-config]').each(function(pos, node) {
      var config = $(node).data('uploader-config');
      var fileUploader = new ActivityUploadFile(config);
      fileUploader.attachEvents();
    });
  })

}());
