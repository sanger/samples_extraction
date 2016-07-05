(function() {

  var DROPZONE_SINGLETON = null;

  function ActivityUploadFile(obj) {
    this.url = obj.url;
    this.identifier = obj.identifier;
    this.node = $("#"+this.identifier);
    this.fileUploadElement = $(".file-upload", this.node);
    this.nextStepElement = $(".next-step", this.node);
    // Get the template HTML and remove it from the doumenthe template HTML and remove it from the doument
    var previewNode = document.querySelector("#"+this.identifier+" .template");
    previewNode.id = "";
    var previewTemplate = previewNode.parentNode.innerHTML;
    previewNode.parentNode.removeChild(previewNode);

    //if (DROPZONE_SINGLETON === null) {
      DROPZONE_SINGLETON = new Dropzone(this.node[0], { // Make the whole body a dropzone
        url: this.url, // Set the url
        method: 'PUT',
        thumbnailWidth: 80,
        thumbnailHeight: 80,
        parallelUploads: 20,
        previewTemplate: previewTemplate,
        autoQueue: false, // Make sure the files aren't queued until manually added
        previewsContainer: "#"+this.identifier+" .previews", // Define the container to display the previews
        clickable: "#"+this.identifier+" .fileinput-button", // Define the element that should be used as click trigger to select files.
        headers: {
              'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
        }
      });
    //};
   this.myDropzone = DROPZONE_SINGLETON;
  };

  ActivityUploadFile.prototype.toggleUploadButtons = function(value) {
    this.specificElementButtons = $(".upload-buttons", this.node);

    if (typeof value === 'undefined') {
      this.fileUploadElement.toggle();
      this.specificElementButtons.toggle();
    } else {
      this.fileUploadElement.toggle(value);
      this.specificElementButtons.toggle(value);
    }
  }

  ActivityUploadFile.prototype.attachEvents = function() {
    var myDropzone = this.myDropzone;
    var obj = this;
    myDropzone.on("success", function() {
      obj.nextStepElement.attr('disabled', false);
      obj.nextStepElement.show();
      obj.toggleUploadButtons(false);
      $(".start", obj.node).attr('disabled', true);
      $('.total-progress', obj.node).hide();

    });

    myDropzone.on("addedfile", function(file) {
      myDropzone.files.forEach(function(storedFile, pos) {
        if (storedFile !== file) {
          myDropzone.removeFile(storedFile);
        }
      });
      $(".start", obj.node).attr('disabled', false);
      obj.nextStepElement.attr('disabled', true);
      obj.nextStepElement.hide();
      obj.singleFileAdded = file;

      setTimeout(function() {
        myDropzone.enqueueFiles(myDropzone.getFilesWithStatus(Dropzone.ADDED));
      }, 500);

    });

    myDropzone.on("removedfile", function(file) {
      obj.singleFileAdded = null;
      $(".start", obj.node).attr('disabled', true);
      obj.nextStepElement.attr('disabled', true);
      obj.nextStepElement.hide();
    });


    // Update the total progress bar
    myDropzone.on("totaluploadprogress", function(progress) {
      $('.total-progress .progress-bar', obj.node).css('width', progress + "%");
    });

    myDropzone.on("sending", function(file, xhr, data) {
      // Show the total progress bar when upload starts
      $('.total-progress', obj.node).show();
      /*$('input[name]', obj.nextStepElement.parent()).each(function(pos, node) {
        data.append($(node).attr('name'), $(node).val());
      });*/
    });

    // Hide the total progress bar when nothing's uploading anymore
    myDropzone.on("queuecomplete", function(progress) {
      $('.total-progress', obj.node).hide();
    });

    $(".start", obj.node).on('click', function() {
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
