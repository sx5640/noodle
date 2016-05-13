$(document).on('ready', function() {

  var global_zoneList;

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

          console.log(data);

          // First clear the article summary list
          $('#zone-list').empty();

          // Display Keywords for entire timeline
          var htmlKeywords = "<div id='top-keywords-list'></div>";
          $('#keywords-container').html(htmlKeywords);

          if (data['keywords'] !== null) {
            var keywordMax = data['keywords'].length < 10 ? data['keywords'].length : 10;

            for (var i = 0; i < keywordMax; i++) {
              var htmlKeyword = "<a href='/' class='top-keywords'>" + data['keywords'][i].keyword + "</a> ";
              var fontWeight = '300';
              if (data['keywords'][i].relevance > 10.0) {
                fontWeight = '500';
              } else
              if (data['keywords'][i].relevance > 3.0) {
                fontWeight = '400';
              } else
              if (data['keywords'][i].relevance > 2.0) {
                fontWeight = '300';
              } else
              if (data['keywords'][i].relevance > 1.0) {
                fontWeight = '200';
              } else {
                fontWeight = '100';
              }
              var appendObject = $(htmlKeyword);
              appendObject.css('font-weight', fontWeight);
              $('#top-keywords-list').append(appendObject);
            }
          }

          // Compile the template with source HTML
          var sourceVisualization = $('#template-visualization').html();
          var templateVisualization = Handlebars.compile(sourceVisualization);

          var sourceZone = $('#template-zone').html();
          var templateZone = Handlebars.compile(sourceZone);

          // Loop through each zone and combine it with the templates
          for ( var i = 0; i < data['zones'].length; i++ ) {
            console.log(data['zones'][i]);

            var zone = data['zones'][i];
            if (zone !== null) {
              if (zone.count > 0) {
                var htmlVisualization = templateVisualization(zone);
                var size = 25 + zone.hotness * 25;
                var visualizationDiv;
                var start_date = new Date(zone.start_time);
                var end_date = new Date(zone.end_time);
                var months = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];
                var start_month = months[start_date.getMonth()];
                var end_month = months[end_date.getMonth()];
                var dateDisplay = "";

                // Display zone summary, eg. keywords, representative article, etc.

                var htmlZone = templateZone(zone.article_list[0]);
                $('#zone-list').append(htmlZone);

                // Append first 5 keywords

                // console.log(zone.keywords.length);
                // var keywordMax2 = zone.keywords.length < 5 ? zone.keywords.length : 5;
                // console.log(keywordMax2);

                if (zone.keywords !== null) {
                  var keywordMax2 = zone.keywords.length < 5 ? zone.keywords.length : 5;

                  if (keywordMax2 > 0) {
                    for (var j = 0; j < keywordMax2; j++) {
                      var htmlZoneKeyword = "<li>" + zone.keywords[j].keyword + "</li>";
                      var appendObject2 = $(htmlZoneKeyword);

                      var fontWeight2 = '200';
                      if (zone.keywords[j].relevance > 3.0) {
                        fontWeight2 = '500';
                      } else
                      if (zone.keywords[j].relevance > 1.0) {
                        fontWeight2 = '400';
                      } else
                      if (zone.keywords[j].relevance > .5) {
                        fontWeight2 = '300';
                      }
                      appendObject2.css('font-weight', fontWeight2);
                      $('.keywords').last().append(appendObject2);
                    }
                  } else {
                    $('.keywords').last().append("<li>No keywords</li>");
                  }
                }

                // Display zone hotness visualization (circle)

                $('.zone').last().prepend(htmlVisualization);
                visualizationDiv = $('.visualization').last();

                visualizationDiv.css('width', size + 'px');
                visualizationDiv.css('height', size + 'px');
                visualizationDiv.css('opacity', .5 + zone.hotness/10/2);
                visualizationDiv.css('font-size', .75 + zone.hotness/4 + 'rem');

                // Display year

                $('.zone').last().prepend("<div class='zone-year'>" + end_date.getFullYear() + "</div>");

                // Display month range of zone, eg. JUNE - JULY

                if (start_month === end_month) {
                  dateDisplay = start_month;
                } else {
                  dateDisplay = start_month + " - " + end_month;
                }
                dateDisplay = dateDisplay.toUpperCase();
                $('.zone').last().prepend("<div class='zone-month'>" + dateDisplay + "</div>");

                // Display verticle zone connector line, except for the first zone
                if (i !== 0) {
                  $('.zone').last().prepend("<div class='zone-connector'></div>");
                }

                // Bind an eventhandler to each newly created zone to handle zooming

                $('.zone').last().on('mouseover', function(eventObject) {
                  $(this).css('color', '#0096bf');

                  // var originalSize = parseInt($(".visualization", this).css('width')) * 2;
                  // console.log(originalSize);
                  // $(".visualization", this).animate({ width: originalSize + "px", height: originalSize + "px" }, 100, "linear");
                });

                $('.zone').last().on('mouseout', function(eventObject) {
                  $(this).css('color', '');
                });

                $('.zone').last().on('click', function(eventObject) {

                  // Retrieve data for zone corresponding to click event
                  var ind = $(this).index();
                  var zone = data['zones'][ind];

                  // Remove zone-list from DOM temporarily
                  global_zoneList = $('#zone-list').detach();

                  // Append new DOM element article-list
                  var htmlArticleList = '<ul class="article-list"></ul>';
                  $('.content-container').append(htmlArticleList);

                  // Construct each article using the article-summary - reuse template-zone for now
                  for (var i = 0; i < zone.count; i++) {
                    var htmlArticle = templateZone(zone.article_list[i]);
                    $('.article-list').append(htmlArticle);
                  }
                });
              } else {

                // If there are no articles, create an empty list item with class zone
                // This is important so that we can use the zone li index to correctly select the right right zone data
                var htmlZone = "<li class='zone'></li>";
                $('#zone-list').append(htmlZone);
              }
            }
          }
        }
      }
    });
  });

})
