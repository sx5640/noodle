$(document).on('ready page:load', function() {

  var global_timeline;
  // var global_articleList; // This isn't needed right now

  // AJAX call to submit search terms and display the article results
  if ($(".userprofile-savedtimeline").length !== 0) {
    $(".userprofile-savedtimeline").on('click', function(eventObject) {
      var url = this.href;
      eventObject.preventDefault();
      $.ajax({
        url: url,
        type: 'GET',
        dataType: 'json',
        success: function (data) {
          $('.userprofile').remove();
          displaySearchResult(data)
        }
      });
    })
  }

  var displaySearchResult = function(data) {

    // Use Handlebars to compile our article summary templates and append the resulting html to the index page
    if (data) {

      var firstNonEmptyZoneDisplayed = false;

      // First clear the timeline title and article summary list
      $('#timeline-header').remove();
      $('#zone-list').empty();

      // Display Keywords for entire timeline
      timeline.replaceKeywords(data['keywords'], 10, $('#top-keywords-list'), 'top-keywords');

      // Compile the template with source HTML
      var sourceVisualization = $('#template-visualization').html();
      var templateVisualization = Handlebars.compile(sourceVisualization);

      var sourceZone = $('#template-zone').html();
      var templateZone = Handlebars.compile(sourceZone);

      // Display Timeline title
      var htmlTimelineTitle = '<div id="timeline-header"><h1 class="timeline-title">Timeline</h1></div>';
      $('#timeline').prepend(htmlTimelineTitle);

      if (data.user && data.user.saved_this_timeline === false) {

        var htmlTimelineSave =  '<h1 id="save-timeline-button"><a id="save-timeline" href="">*</a></h1>';
        $('#timeline-header').append(htmlTimelineSave);

        // Add event handler for saving the timeline to the user model
        $('#save-timeline').on('click', function(eventObject) {
          eventObject.preventDefault();

          var url = '/users/' + data.user.user_id + '/saved_timelines';

          $.ajax({
            url: url,
            type: 'POST',
            dataType: 'json',
            data: {
              search_string: data.search_info.search_string,
              start_time: data.search_info.start_time,
              end_time: data.search_info.end_time
            },
            success: function(data) {
              console.log(data);
              $('#save-timeline-button').html('<h1 class="timeline-saved-message">saved</h1>');
            }
          });
        });
      }

      // Loop through each zone and combine it with the templates
      for ( var i = data['zones'].length - 1; i >= 0 ; i-- ) {
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

            // Append first 3 keywords
            timeline.replaceKeywords(zone.keywords, 3, $('.keywords').last(), 'top-keywords-zone', .25);

            // Display number of articles
            var htmlNumberOfArticles = zone.article_list.length;
            if (zone.article_list.length === 0 || zone.article_list.length > 1) {
              htmlNumberOfArticles += ' stories';
            } else {
              htmlNumberOfArticles += ' story';
            }
            $('.number-of-articles').last().html(htmlNumberOfArticles);

            // Display zone hotness visualization (circle)
            $('.zone').last().prepend(htmlVisualization);
            visualizationDiv = $('.visualization').last();

            visualizationDiv.css('width', size + 'px');
            visualizationDiv.css('height', size + 'px');
            visualizationDiv.css('opacity', .35 + zone.hotness * .05);
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
            if (firstNonEmptyZoneDisplayed) {
              $('.zone').last().prepend("<div class='zone-connector'></div>");
            }

            // Bind an eventhandler to each newly created zone to handle zooming
            // When user clicks into a zone, display the articles view
            $('.zone').last().on('click', function(eventObject) {

              // Retrieve data for zone corresponding to click event
              var zoneIndex = data['zones'].length - $(this).index() - 1;
              var zone = data['zones'][zoneIndex];

              // Remove timeline from DOM temporarily
              global_timeline = $('#timeline').detach();

              // Append new DOM element article-list
              var htmlArticleList = '<ul class="article-list"></ul>';
              $('.content-container').append(htmlArticleList);

              // Add a 'back to timeline' link - the most basic timeline navigation
              var htmlBackToTimeline = '<a id="back-to-timeline" href="">Back to Timeline</a>';
              $('#timeline-nav').html(htmlBackToTimeline);

              // Construct each article using the article-summary - reuse template-zone for now
              for (var i = 0; i < zone.count; i++) {
                var htmlArticle = templateZone(zone.article_list[i]);
                $('.article-list').append(htmlArticle);

                // Append first 3 keywords
                timeline.replaceKeywords(zone.keywords, 3, $('.keywords').last(), 'top-keywords-zone', .25);
              }

              // Show the top of the document instead of the bottom
              $(document).scrollTop(0);
            });

            if (!firstNonEmptyZoneDisplayed) {
              firstNonEmptyZoneDisplayed = true;
            }
          } else {

            // If there are no articles, create an empty list item with class zone
            // This is important so that we can use the zone li index to correctly select the right right zone data
            var htmlZone = "<li class='zone'></li>";
            $('#zone-list').append(htmlZone);
          }
        }
      }

      // Render minimap

      minimap.render(data['zones']);
    }
  }


  $('.search-form').on('submit', function(eventObject) {
    eventObject.preventDefault();
    var url = '/articles/search?utf8=%E2%9C%93&search=' + $('#search').val();

    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      success: displaySearchResult
    });
  });
  // Add event handler to go back to timeline via AJAX
  $('#timeline-nav').on('click', function(eventObject) {
    eventObject.preventDefault();

    // Detach article list and reattach timeline
    $('article-list').remove();
    $('.content-container').html(global_timeline);

    // Remove back link
    $('#timeline-nav').empty();
  });

  $(window).scroll(function() {
    console.log($(window).scrollTop());

    var documentHeight = $(document).height();
    var windowHeight = $(window).height();
    var navHeight = $('.nav-bar').outerHeight();
    var zoneListHeight = $('#zone-list').outerHeight();
    var headerHeight = documentHeight - zoneListHeight;
    var documentY = $(window).scrollTop();
    // var searchSectionHeight = $('#search-section').outerHeight();
    // var keywordsContainerHeight = $('#keywords-container').outerHeight();
    // var timelineNavHeight = $('#timeline-nav').outerHeight();

    // console.log('document height: ', documentHeight);
    // console.log('window height: ', windowHeight);
    // console.log('nav height: ', navHeight);
    // console.log('zone list height: ', zoneListHeight);
    // console.log('document y: ', documentY);
    // console.log('search height: ', searchSectionHeight);
    // console.log('keywords height: ', keywordsContainerHeight);
    // console.log('timeline nav height: ', timelineNavHeight);

    var timelineY = documentY - headerHeight + windowHeight/2;

    // console.log('timeline y: ', timelineY);

    var minimapY = timelineY * (500/zoneListHeight);

    // console.log('minimap y: ', minimapY);

    var index = Math.floor(minimapY / 500 * $('.circle').size());

    if (index < 0) {
      index = 0;
    }

    var circleInFocus = $('.circle').eq(index);

    // console.log('index: ', index);
    // console.log('circle in focus: ', circleInFocus);

    var circleWidth = circleInFocus.css('width');
    var newCircleWidth = parseInt(circleWidth) * 2;
    // console.log('circleWidth: ', circleWidth);
    // console.log('newCircleWidth: ', newCircleWidth);

    // circleInFocus.css('width', newCircleWidth + 'px');
    // circleInFocus.css('height', newCircleWidth + 'px');

    // circleInFocus.css('width', '100px');
    // circleInFocus.css('height', '100px');

    // circleInFocus.css('background-color', 'black');

    $('.minimap-circle-pop').removeClass('minimap-circle-pop');
    if (!circleInFocus.hasClass('minimap-circle-pop')) {
      circleInFocus.toggleClass('minimap-circle-pop');
    }

    // console.log('new circleInFocus: ', circleInFocus.css('width'));
  });
});
