$(document).on('ready', function() {

  // AJAX call to submit search terms and display the article results

  $('.search-form').on('submit', function(eventObject) {

    eventObject.preventDefault();

    var url = '/articles/search?utf8=%E2%9C%93&search=' + $('#search').val();

    $.ajax({
        url: url,
        type: 'GET',
        dataType: 'json',
        success: function(data) {

          // Use Handlebars to compile our article summary templates and append the resulting html to the index page

          if (data) {

            // First clear the article summary list
            $('.article-summary-list').empty();

            var source = $('#article-summary-list-item').html();
            var template = Handlebars.compile(source);

            // Loop through each article and combine it with the template
            for ( var i = 0; i < data.length; i++ ) {
              var html = template(data[i]);
              $('.article-summary-list').append(html);
            }
          }
        }
    })
  });

})
