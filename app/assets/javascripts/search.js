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
          $('#zone-list').empty();

          // Compile the template with source HTML
          var sourceVisualization = $('#template-visualization').html();
          var templateVisualization = Handlebars.compile(sourceVisualization);

          var sourceZone = $('#template-zone').html();
          var templateZone = Handlebars.compile(sourceZone);

          // Loop through each zone and combine it with the templates
          for ( var i = 0; i < data.length; i++ ) {
            console.log(data[i]);

            var zone = data[i];
            if (zone !== null && zone.count > 0) {
              var htmlVisualization = templateVisualization(zone);
              var size = 50 + zone.hottness * 25;
              var visualizationDiv;

              $('#zone-list').append(htmlVisualization);
              visualizationDiv = $('.visualization').last();

              visualizationDiv.css('width', size + 'px');
              visualizationDiv.css('height', size + 'px');
              visualizationDiv.css('opacity', .5 + zone.hottness/10/2);
              visualizationDiv.css('font-size', 1 + zone.hottness/2 + 'rem');

              var htmlZone = templateZone(zone.article_list[0]);
              $('#zone-list').append(htmlZone);
            }
          }
        }
      }
    });
  });

})
