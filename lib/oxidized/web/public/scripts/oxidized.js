// dayjs.extend(utc);

var convertTime = function() {
  /* Convert UTC times to local browser times
  *  Requires that the times on the server are UTC
  *  Requires a class name of `time` to be set on element desired to be changed
  *  Requires that element has an attribute `epoch` containing the seconds since
  *  1.1.1970 UTC.
  */
  $('.time').each(function() {
    var content = $(this).text();
    if(content === 'never' || content === 'unknown' || content === '') {
      return;
    }
    var epoch = $(this).attr('epoch');
    if(epoch === undefined) {
      return;
    }
    var utcTime = Number(epoch);
    var dj = dayjs.unix(utcTime).local();

    $(this).text(dj.format('YYYY-MM-DD HH:mm:ss [(UTC]Z[)]'));
  });
};

$(function() {
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
