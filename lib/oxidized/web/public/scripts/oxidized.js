// Add a line for a new file to upload
var add_file_upload = function() {
  var rancidDbDiv = $("div[id^='rancidDb']:last");
  var num = parseInt(rancidDbDiv.prop("id").match(/\d+/g)) + 1;
  rancidDbDiv.clone(true)
    .prop("id", "rancidDb" + num)
    .insertAfter(rancidDbDiv);
  $("input[id^='file']:last")
    .prop("id", "file" + num)
    .prop("name", "file" + num)
    .parents('.input-group')
    .find(':text')
    .val('');
  $("input[id^='group']:last")
    .prop("id", "group" + num)
    .prop("name", "group" + num);
};

var onFileSelected = function() {
  $(document).on('change', '.btn-file :file', function() {
    var input = $(this),
        numFiles = input.get(0).files ? input.get(0).files.length : 1,
        label = input.val().replace(/\\/g, '/').replace(/.*\//, '');
    input.trigger('fileSelect', [numFiles, label]);
  });
};

var convertTime = function() {
  /* Convert UTC times to local browser times
  *  Requires that the times on the server are UTC
  *  Requires a class name of `time` to be set on element desired to be changed
  *  Requires that element have a text in the format of `YYYY-mm-dd HH:MM:SS`
  *  See ytti/oxidized-web #16
  */
  $('.time').each(function() {
    var content = $(this).text();
    if(content === 'never' || content === 'unknown' || content === '') { return; }
    var utcTime = content.split(' ');
    var date = new Date(utcTime[0] + 'T' + utcTime[1] + 'Z');
    var year = date.getFullYear();
    var month = ("0"+(date.getMonth()+1)).slice(-2);
    var day = ("0" + date.getDate()).slice(-2);
    var hour = ("0" + date.getHours()).slice(-2);
    var minute = ("0" + date.getMinutes()).slice(-2);
    var second = ("0" + date.getSeconds()).slice(-2);
    var timeZone = date.toString().match(/[A-Z]{3,4}[+-][0-9]{4}/)[0];
    $(this).text(year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second + ' ' + timeZone);
  });
};

$(function() {
  onFileSelected();
  convertTime();
  // Add a row to the migration form
  $("#add").click(function() {
    add_file_upload();
  });

  // Updates textbox with filename on fileSelect event
  $('.btn-file :file').on('fileSelect', function(e, numFiles, label) {
    $(this).parents('.input-group').find(':text').val(label);
  });

  // Reloads the nodes from a source by calling the /reload.json URI
  $('#reload').click(function() {
    $.get(window.location.pathname.replace(/nodes.*/g, '')+'reload.json')
      .done(function(data) {
        $('#flashMessage')
        .removeClass('alert-danger')
        .addClass('alert-success')
        .text(data);
      })
      .fail(function() {
        var data = 'Unable to reload nodes'
        $('#flashMessage')
          .removeClass('alert-success')
          .addClass('alert-danger')
          .text(data);
      })
      .always(function() {
        $('#flashMessage').removeClass('hidden');
      });
  });

  // Update timestamp on next button click for DataTables
  $('.paginate_button').on('click', function() {
    convertTime();
  });
});
