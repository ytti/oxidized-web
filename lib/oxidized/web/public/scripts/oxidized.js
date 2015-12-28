// Convert UTC times to local browser times
// Requires that the times on the server are UTC
// Requires a class name of `time` to be set on element desired to be changed
// Requires that element have a text in the format of `YYYY-mm-dd HH:MM:SS`
// See ytti/oxidized-web #16
$(function() {
  $('.time').each(function() {
    var utcTime = $(this).text().split(' ');
    var date = new Date(utcTime[0] + 'T' + utcTime[1] + 'Z');
    var year = date.getFullYear();
    var month = ("0"+(date.getMonth()+1)).slice(-2);
    var day = ("0" + date.getDate()).slice(-2);
    var hour = ("0" + date.getHours()).slice(-2);
    var minute = ("0" + date.getMinutes()).slice(-2);
    var second = ("0" + date.getSeconds()).slice(-2);
    var timeZone = date.toString().match(/\(.*\)/)[0].match(/[A-Z]/g).join('');
    $(this).text(year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second + ' ' + timeZone);
  });
});
