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
              var size = 25 + zone.hottness * 25;
              var visualizationDiv;
              var start_date = new Date(zone.start_time);
              var end_date = new Date(zone.end_time);
              var months = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];
              var start_month = months[start_date.getMonth()];
              var end_month = months[end_date.getMonth()];
              var dateDisplay = "";

              // Display verticle zone connector line, except for the first zone
              if (i !== 0) {
                $('#zone-list').append("<div class='zone-connector'></div>");
              }

              // Display month range of zone, eg. JUNE - JULY

              if (start_month === end_month) {
                dateDisplay = start_month;
              } else {
                dateDisplay = start_month + " - " + end_month;
              }
              dateDisplay = dateDisplay.toUpperCase();
              $('#zone-list').append("<div class='zone-month'>" + dateDisplay + "</div>");

              // Display year

              $('#zone-list').append("<div class='zone-year'>" + end_date.getFullYear() + "</div>");

              // Display zone hotness visualization (circle)

              $('#zone-list').append(htmlVisualization);
              visualizationDiv = $('.visualization').last();

              visualizationDiv.css('width', size + 'px');
              visualizationDiv.css('height', size + 'px');
              visualizationDiv.css('opacity', .5 + zone.hottness/10/2);
              visualizationDiv.css('font-size', .75 + zone.hottness/4 + 'rem');

              // Display zone summary, eg. keywords, representative article, etc.

              var htmlZone = templateZone(zone.article_list[0]);
              $('#zone-list').append(htmlZone);
            }
          }
        }
      }
    });
  });

})
