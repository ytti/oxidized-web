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
