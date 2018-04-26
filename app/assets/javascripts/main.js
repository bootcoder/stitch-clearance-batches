$(document).ready(function () {
  reportSortListener();
});

var reportSortListener = function () {
  $('#sort-select').on('change', function () {
    $('#btn-sort-select').click();
  });
};
